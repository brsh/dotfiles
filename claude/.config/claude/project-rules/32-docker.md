---
trigger: glob
glob: "**/{Dockerfile*,docker-compose*.yml,docker-compose*.yaml,.dockerignore}"
description: "Docker and container best practices for sysadmin-managed workloads"
---

# Docker / Container Rules

These rules apply to Docker and Podman (which uses the same CLI interface).
RHEL/Rocky environments prefer Podman; Ubuntu environments typically use Docker.

---

## Dockerfile Best Practices

### Template

```dockerfile
# Pin a specific version — never use :latest in production
FROM python:3.12-slim AS base

# Metadata
LABEL maintainer="your.email@example.com"
LABEL org.opencontainers.image.description="Description of what this image does"

# Install dependencies as root, then switch to non-root user
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*   # clean package cache in same layer

# Create non-root user and group
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --shell /bin/bash --create-home appuser

WORKDIR /app

# Multi-stage: dependency install stage
FROM base AS deps
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Final stage — copy only what's needed
FROM base AS final
COPY --from=deps /root/.local /home/appuser/.local
COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["python", "-m", "myapp"]
CMD ["--config", "/app/config.yaml"]
```

---

## Key Dockerfile Rules

### Pin Base Image Versions

```dockerfile
# Good — specific version, reproducible builds
FROM ubuntu:22.04
FROM python:3.12-slim-bookworm
FROM nginx:1.25-alpine

# Bad — changes without warning
FROM ubuntu:latest
FROM python:latest
```

Use digest pins for maximum reproducibility in production:
```dockerfile
FROM python:3.12-slim@sha256:abc123...
```

### Run as Non-Root

```dockerfile
# Create a dedicated user
RUN useradd --uid 1001 --no-create-home --shell /bin/false appuser
USER appuser
```

Running as root in a container is a container escape risk. Always add a non-root user.

### Minimize Layers and Image Size

```dockerfile
# Good — combines into one layer, cleans up in same RUN
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Bad — separate RUN commands create extra layers; cleanup in separate layer is ineffective
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*
```

Use slim or alpine variants when possible (`python:3.12-slim`, `node:20-alpine`).

### Layer Caching — Copy Dependencies Before Source

```dockerfile
# Good — dependencies layer cached separately from source changes
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

# Bad — any source change invalidates the pip install layer
COPY . .
RUN pip install -r requirements.txt
```

---

## .dockerignore

Always create a `.dockerignore` file:

```
.git
.gitignore
.env
.env.*
*.md
__pycache__
*.pyc
*.pyo
.pytest_cache
.coverage
htmlcov/
node_modules/
dist/
build/
*.log
Dockerfile
docker-compose*.yml
.windsurf/
```

This prevents secrets, large build artifacts, and unnecessary files from entering
the build context and potentially the image.

---

## docker-compose / Compose Files

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: final              # multi-stage target
    image: myapp:${VERSION:-dev}
    container_name: myapp
    restart: unless-stopped
    user: "1001:1001"
    read_only: true              # read-only root filesystem
    tmpfs:
      - /tmp                     # writable temp space
    environment:
      - APP_ENV=${APP_ENV:-production}
      - LOG_LEVEL=${LOG_LEVEL:-info}
    env_file:
      - .env                     # never commit .env
    ports:
      - "127.0.0.1:8080:8080"   # bind to localhost only unless external access needed
    volumes:
      - app_data:/app/data       # named volume (preferred over bind mounts for data)
      - ./config:/app/config:ro  # bind mount config read-only
    networks:
      - backend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s
    deploy:
      resources:
        limits:
          memory: 512m
          cpus: "0.50"

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password   # Docker secrets
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - backend
    secrets:
      - db_password

volumes:
  app_data:
  db_data:

networks:
  backend:
    driver: bridge

secrets:
  db_password:
    file: ./secrets/db_password.txt   # file not committed — for local dev
    # For production use external secrets: external: true
```

---

## Override Files for Local Development

```yaml
# docker-compose.override.yml (auto-loaded in development, not committed)
services:
  app:
    build:
      target: dev               # use a dev stage with hot reload
    volumes:
      - .:/app                  # mount source for live editing
    environment:
      - DEBUG=true
    ports:
      - "8080:8080"             # expose directly in dev
```

---

## Security Practices

- **No secrets in environment variables in Dockerfiles** — use `--env-file`, Docker
  secrets, or vault injection at runtime
- **No secrets in image layers** — once in a layer, they can be extracted even after
  removal in a later layer
- **Read-only filesystem** where possible (`read_only: true` in compose, `--read-only` flag)
- **Drop capabilities**:
  ```yaml
  cap_drop:
    - ALL
  cap_add:
    - NET_BIND_SERVICE   # only add what's needed
  ```
- **Resource limits** — always set memory limits to prevent runaway containers
- **Network segmentation** — put services that don't need external access on internal
  networks only

---

## Podman Compatibility Notes (RHEL/Rocky)

Podman is largely Docker CLI-compatible. Key differences:

```bash
# Podman uses rootless containers by default
podman build -t myapp .
podman run -d --name myapp myapp
podman compose up -d      # or: podman-compose up -d (needs podman-compose package)

# Systemd integration (Podman's advantage over Docker)
podman generate systemd --name myapp --new > /etc/systemd/system/container-myapp.service
systemctl enable --now container-myapp

# Podman doesn't have a daemon — rootless by default
# Volumes in rootless mode: host UIDs may need mapping
podman run --userns=keep-id -v ./data:/app/data myapp
```

---

## Common Pitfalls to Flag

- `FROM ... :latest` → always pin a version
- Running as root (`USER root` or no `USER` directive) → add a non-root user
- No `.dockerignore` → suggest creating one; check for `.env` exposure
- Secrets in `ENV` directives → flag as security risk; suggest runtime injection
- Package install without `rm -rf /var/lib/apt/lists/*` → increases image size
- `COPY . .` before dependency install → hurts layer caching
- Ports bound to `0.0.0.0` without intent → suggest `127.0.0.1:port:port`
- No `HEALTHCHECK` → suggest adding one
- No resource limits in compose → suggest adding memory limits
- `docker-compose` (v1) commands → use `docker compose` (v2) instead
- Storing persistent data in container filesystem → suggest named volumes
