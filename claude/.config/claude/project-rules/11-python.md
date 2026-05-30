---
trigger: glob
glob: "**/*.py"
description: "Python scripting best practices for sysadmin automation and tooling"
---

# Python Rules

These rules are calibrated for Python used in **sysadmin scripting and automation**
contexts — not large application development. Focus is on readability, reliability,
and maintainability of scripts that run in production environments.

---

## Script Structure

Every script should have this basic structure:

```python
#!/usr/bin/env python3
"""
Brief description of what this script does.

Usage:
    python3 script_name.py --target server01 --action restart

Requirements:
    pip install -r requirements.txt
    Environment variable: SERVICE_API_KEY
"""

import argparse
import logging
import sys
from pathlib import Path


def main() -> int:
    """Main entry point. Returns exit code."""
    args = parse_args()
    setup_logging(args.verbose)
    
    # ... logic here ...
    
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", required=True, help="Target hostname or IP")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    return parser.parse_args()


def setup_logging(verbose: bool = False) -> None:
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        level=level,
    )


if __name__ == "__main__":
    sys.exit(main())
```

---

## Style and Formatting

- Follow **PEP 8**. Use `ruff` (preferred) or `black` for auto-formatting.
- **Line length**: 100 characters max (88 is black's default; 100 is fine for scripts).
- **Type hints**: Add them to function signatures. They serve as documentation and
  enable static analysis.
  ```python
  def get_disk_usage(path: str, threshold_gb: float = 10.0) -> dict[str, float]:
  ```
- **Docstrings**: One-line for simple functions, multi-line for complex ones.
- Use **f-strings** for string interpolation: `f"Host {hostname} is unreachable"` —
  not `.format()` or `%` style.

---

## File and Path Handling

Use `pathlib.Path` instead of `os.path` string manipulation:

```python
from pathlib import Path

# Good
log_dir = Path("/var/log/myscript")
log_dir.mkdir(parents=True, exist_ok=True)
log_file = log_dir / "output.log"
content = log_file.read_text(encoding="utf-8")

# Avoid
import os
log_dir = "/var/log/myscript"
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, "output.log")
```

---

## Error Handling

```python
import logging
import sys

logger = logging.getLogger(__name__)

# Catch specific exceptions — not bare except:
try:
    result = connect_to_server(hostname, timeout=30)
except ConnectionTimeoutError as e:
    logger.error("Connection to %s timed out: %s", hostname, e)
    sys.exit(1)
except PermissionError as e:
    logger.error("Permission denied connecting to %s: %s", hostname, e)
    sys.exit(1)
except Exception as e:
    logger.exception("Unexpected error: %s", e)   # logs full traceback
    sys.exit(1)
```

- Use `logger.exception()` inside except blocks — it includes the full traceback.
- Return meaningful exit codes: `0` = success, `1` = error, `2` = usage error.
- Never use bare `except:` — it catches `KeyboardInterrupt` and `SystemExit` too.

---

## Logging (use the logging module, not print)

```python
import logging

# Module-level logger (best practice)
logger = logging.getLogger(__name__)

# Usage
logger.debug("Connecting to %s on port %d", host, port)
logger.info("Successfully retrieved %d records", len(records))
logger.warning("Retrying in %d seconds (attempt %d/%d)", delay, attempt, max_attempts)
logger.error("Failed to write to %s: %s", path, error)
logger.critical("Cannot reach domain controller — aborting")
```

Configure logging in `main()`, not at module level. This allows the module to be
imported without side effects.

---

## Subprocess and Shell Commands

```python
import subprocess

# Preferred — structured, safe, captures output
result = subprocess.run(
    ["systemctl", "status", "nginx"],
    capture_output=True,
    text=True,
    check=False,         # don't raise on non-zero exit
    timeout=30,
)
if result.returncode != 0:
    logger.error("systemctl failed: %s", result.stderr.strip())

# When you need to check=True (raises CalledProcessError on failure)
try:
    subprocess.run(["apt-get", "update"], check=True, timeout=120)
except subprocess.CalledProcessError as e:
    logger.error("apt-get update failed with exit code %d", e.returncode)
```

Never use `os.system()` — it doesn't capture output and is harder to handle safely.
Never use `shell=True` with user-supplied input — it's a command injection risk.

---

## Configuration and Secrets

```python
import os
from configparser import ConfigParser
from dotenv import load_dotenv   # pip install python-dotenv

# Environment variables (CI/CD, containers, automated scripts)
load_dotenv()   # loads .env file if present (never commit .env to git)
api_key = os.environ["API_KEY"]          # raises KeyError if missing — intentional
db_password = os.getenv("DB_PASSWORD")   # returns None if missing

# Config files for non-secret settings
config = ConfigParser()
config.read("config.ini")
server = config.get("DEFAULT", "server_hostname")
```

Never hardcode credentials, tokens, or passwords. If a secret needs to be in a file,
use a `.env` file (added to `.gitignore`), or reference a vault/secrets manager.

---

## Virtual Environments

Always use a virtual environment. For scripts shared with a team:

```bash
python3 -m venv .venv
source .venv/bin/activate       # Linux/macOS
.\.venv\Scripts\Activate.ps1    # Windows PowerShell

pip install -r requirements.txt
```

Pin versions in `requirements.txt`:

```
requests==2.31.0
paramiko==3.4.0
python-dotenv==1.0.1
```

Use `pip freeze > requirements.txt` to capture current state.

---

## Sysadmin-Relevant Libraries

| Library | Purpose |
|---------|---------|
| `paramiko` | SSH connections and SFTP |
| `requests` / `httpx` | HTTP/REST API calls |
| `ldap3` | Active Directory / LDAP queries |
| `pywinrm` | Windows Remote Management (WinRM) |
| `boto3` | AWS SDK |
| `azure-identity` + `azure-mgmt-*` | Azure management APIs |
| `python-dotenv` | `.env` file loading |
| `rich` | Better terminal output (tables, progress bars) |
| `typer` | Modern CLI argument parsing (built on Click) |
| `schedule` | Simple task scheduling |
| `pysnmp` | SNMP queries for network devices |

---

## Common Patterns for Sysadmin Scripts

**Retry with backoff:**

```python
import time
from functools import wraps

def retry(max_attempts: int = 3, delay: float = 2.0, backoff: float = 2.0):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            current_delay = delay
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts:
                        raise
                    logger.warning("Attempt %d/%d failed: %s. Retrying in %.1fs...",
                                   attempt, max_attempts, e, current_delay)
                    time.sleep(current_delay)
                    current_delay *= backoff
        return wrapper
    return decorator
```

**Progress on long-running operations:**

```python
from rich.progress import track

for server in track(server_list, description="Checking disk usage..."):
    check_disk(server)
```

---

## Common Pitfalls to Flag

- `os.system()` → use `subprocess.run()`
- `shell=True` with variable input → injection risk, flag it
- `print()` for operational output → use `logging`
- Bare `except:` → use `except Exception as e:` at minimum
- Mutable default arguments: `def func(items=[])` → use `def func(items=None)` then
  `if items is None: items = []`
- String concatenation in loops → use `"".join(list)` or f-strings
- Missing `if __name__ == "__main__"` guard → module can't be safely imported
- Missing `encoding` in `open()` → `open(path, "r", encoding="utf-8")`
