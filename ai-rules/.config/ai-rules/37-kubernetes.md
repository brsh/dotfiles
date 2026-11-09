---
trigger: model_decision
description: "Kubernetes, Helm, and Kustomize best practices — activate when working with K8s manifests, Helm charts, or cluster operations"
---

# Kubernetes / Helm / Kustomize Rules

> **Stub — expand as patterns emerge.** This file covers Kubernetes manifests, Helm charts, and Kustomize overlays.

---

## General Principles

- Prefer declarative manifests over imperative `kubectl` commands for anything repeatable.
- Always specify resource requests and limits for containers.
- Use namespaces to isolate workloads; never deploy to `default`.
- Pin container image tags to specific versions or digests — never use `latest` in production.
- Use `kubectl diff` or `--dry-run=server` before applying changes.
- Label resources consistently: `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/version` at minimum.

---

## Helm

- Use `values.yaml` for defaults; override per-environment with `values.<env>.yaml`.
- Validate rendered output: `helm template | kubectl apply --dry-run=server -f -`.
- Keep chart dependencies pinned in `Chart.lock`.
- Use `helm diff` plugin to preview upgrades before applying.

---

## Kustomize

- Use overlays for environment-specific configuration, not in-line patches in the base.
- Prefer `configMapGenerator` and `secretGenerator` over raw manifests for config data.
