---
trigger: always_on
description: "Git best practices — commit conventions, branching, secrets hygiene, .gitignore, and workflow"
---

# Git Best Practices

These rules apply to all projects using git. The primary concerns for a sysadmin
scripting environment are: keeping secrets out of history, writing useful commit
messages, and maintaining a clean repo structure.

---

## The Cardinal Rule: Never Commit Secrets

**This is the single most important git rule.** Once a secret is committed, assume
it is compromised — even if you immediately rewrite history. It may have already
been pushed, cloned, cached, or scanned by automated tools.

### What counts as a secret

- Passwords, API keys, tokens, connection strings
- Private keys (`.pem`, `.key`, `.pfx`, `.p12`)
- Azure credentials (`az login` tokens, service principal secrets)
- AWS credentials (`~/.aws/credentials` content)
- `.env` files with real values
- Hardcoded credentials in any script, even commented out

### Prevention

```bash
# Use pre-commit hooks to scan before every commit
# Install: pip install pre-commit  (or via pipx)
# Or: winget install pre-commit  (Windows)

# .pre-commit-config.yaml in repo root:
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: detect-private-key
      - id: check-added-large-files
        args: ['--maxkb=500']
      - id: end-of-file-fixer
      - id: trailing-whitespace
```

```bash
pre-commit install    # installs the hook into .git/hooks/pre-commit
pre-commit run --all-files  # scan existing files
```

### If a secret was already committed

```bash
# Immediate steps:
# 1. Rotate the secret first — before doing anything else
# 2. Remove it from history (this rewrites history — coordinate with team)
git filter-repo --path secrets.env --invert-paths   # remove a specific file
git filter-repo --replace-text <(echo 'old-secret==>REDACTED')  # scrub a value

# Or use BFG Repo Cleaner (simpler for password scrubbing):
java -jar bfg.jar --replace-text passwords.txt myrepo.git

# Force push (requires team coordination and protected branch bypass)
git push --force-with-lease origin main

# 3. Notify anyone who has cloned the repo that they must re-clone
```

---

## .gitignore — Start With This Template

Every repo should have a `.gitignore`. Create it before the first commit:

```gitignore
# Secrets and credentials (ALWAYS ignore these patterns)
*.env
.env.*
!.env.example          # allow the example/template file
*.pem
*.key
*.p12
*.pfx
secrets/
credentials/
*_secret*
*_password*
*_credentials*
.secrets

# Azure / cloud credentials
.azure/
.aws/
*.azureauth

# PowerShell
# (session transcripts, credential exports, temp output)
*.transcript.txt
Export-Clixml.xml
*-cred.xml

# Python
__pycache__/
*.pyc
*.pyo
.venv/
venv/
.pytest_cache/
*.egg-info/
dist/
build/
.coverage
htmlcov/

# .NET / C#
bin/
obj/
*.user
.vs/
*.suo
TestResults/
publish/

# Terraform
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars          # contains real values — commit *.tfvars.example instead
.terraform.lock.hcl   # usually committed (locks provider versions)
crash.log

# Ansible
*.retry
vault_password_file
.vault_pass

# Docker
.env              # already covered above, but explicit here

# OS
.DS_Store
Thumbs.db
desktop.ini

# Logs and temp
*.log
tmp/
temp/
```

---

## Commit Messages

Good commit messages make `git log`, `git blame`, and PR reviews useful.
Bad commit messages make debugging a nightmare months later.

### Format

```
<type>: <imperative short summary under 72 chars>

<optional body — explain WHY, not WHAT>

<optional footer — issue refs, breaking changes>
```

### Types (Conventional Commits — recommended)

| Type | When to use |
|------|------------|
| `feat` | New functionality added |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `chore` | Tooling, dependency updates, repo maintenance |
| `refactor` | Code restructured without behavior change |
| `test` | Adding or updating tests |
| `security` | Security fix or hardening |
| `ci` | CI/CD pipeline changes |

### Examples

```
# Good
feat: add -WhatIf support to Remove-StaleAdAccounts
fix: correct Get-ADUser filter to use server-side filtering
security: remove hardcoded service account password from config
docs: add prerequisite RSAT modules to script header
refactor: extract credential logic into Get-StoredCredential helper
chore: update Pester to 5.6.1

# Bad
fix: stuff
update script
WIP
changes
Brian's edits
```

### Summary rules

- **Imperative mood**: "Add feature" not "Added feature" or "Adding feature"
- **No period** at the end of the summary line
- **72-character limit** on the summary line
- **Body explains why**, not what — the diff shows what; the message explains the intent
- **Reference issues** in footer: `Closes #42` or `See ADO #1234`

---

## Branching

For solo/small-team sysadmin script repos, keep it simple:

```
main (or master)     — stable, tested, deployable
  └── fix/short-description
  └── feat/short-description
  └── chore/short-description
```

For larger team repos or repos that feed CI/CD pipelines:

```
main                 — production (protected, requires PR)
develop              — integration branch (merges to main via PR)
  └── feat/add-laps-retrieval
  └── fix/ad-filter-encoding-issue
  └── security/remove-plaintext-creds
```

### Branch naming

```bash
feat/add-user-provisioning-script
fix/get-aduser-empty-result-on-disabled
security/rotate-service-account-handling
chore/update-pester-and-psscriptanalyzer
docs/add-ad-permission-requirements
```

- Lowercase, hyphens only (no underscores, no spaces, no slashes in segment names)
- Short but descriptive — enough to understand without opening the branch

---

## Repository Structure for Script Projects

```
my-script-project/
├── .gitignore
├── .pre-commit-config.yaml
├── README.md
├── CHANGELOG.md           # optional but useful for shared scripts
├── src/
│   ├── Invoke-UserCleanup.ps1
│   └── Get-DiskReport.ps1
├── tests/
│   └── Invoke-UserCleanup.Tests.ps1
├── docs/
│   └── prerequisites.md
└── .env.example           # template showing required vars, no real values
```

The `.env.example` pattern:
```bash
# .env.example — commit this
SERVICE_ACCOUNT_USER=svc-myscript
SERVICE_ACCOUNT_PASS=REPLACE_WITH_ACTUAL_VALUE
TARGET_DC=dc01.contoso.com

# .env — never commit this (in .gitignore)
SERVICE_ACCOUNT_USER=svc-myscript
SERVICE_ACCOUNT_PASS=ActualPassword123!
TARGET_DC=dc01.contoso.com
```

---

## Useful Git Commands for Day-to-Day Work

```bash
# Status and review
git status
git diff                          # unstaged changes
git diff --staged                 # staged changes (about to commit)
git log --oneline --graph --all   # visual branch history
git log -p -- path/to/file        # history of a specific file with diffs

# Staging
git add -p                        # interactive staging — review each hunk before adding
                                  # (don't use 'git add .' blindly on scripts with secrets)

# Undoing
git restore <file>                # discard unstaged changes (non-destructive)
git restore --staged <file>       # unstage a file (keep changes in working dir)
git commit --amend --no-edit      # fix last commit (add forgotten file, same message)
git revert HEAD                   # create a new commit that undoes the last one (safe for shared branches)
git reset --soft HEAD~1           # undo last commit, keep staged changes (local only)

# Stashing
git stash push -m "WIP: half-done error handling"
git stash list
git stash pop

# Comparing and searching
git log --all --grep="password"   # find commits mentioning "password" in message
git log -S "plaintext_secret"     # find commits that added/removed a string
git blame src/script.ps1          # who last changed each line

# Remote
git fetch --prune                 # update remote refs, clean up deleted remote branches
git pull --rebase                 # pull with rebase (cleaner history than merge)
git push --force-with-lease       # force push safely (fails if remote changed under you)
```

---

## Global Git Configuration (run once per machine)

```bash
git config --global user.name "Brian Sheaffer"
git config --global user.email "brian@example.com"

# Default branch name
git config --global init.defaultBranch main

# Use VS Code / Windsurf as the merge/diff tool
git config --global core.editor "code --wait"

# Windows: handle line endings (critical for scripts used cross-platform)
git config --global core.autocrlf input   # on Linux/macOS: convert CRLF to LF on commit
git config --global core.autocrlf true    # on Windows: convert to CRLF on checkout, LF on commit

# Rebase by default on pull (cleaner history)
git config --global pull.rebase true

# Always verify before force-push
git config --global alias.pushf "push --force-with-lease"

# Useful aliases
git config --global alias.lg "log --oneline --graph --all --decorate"
git config --global alias.st "status --short --branch"
git config --global alias.staged "diff --staged"
```

---

## Line Endings (CRLF vs LF) — Sysadmin Specific

This is especially important for scripts used on both Windows and Linux:

```bash
# In repo root: .gitattributes (commit this file)
# Normalize line endings stored in git to LF
* text=auto

# Force LF for scripts run on Linux/Unix
*.sh text eol=lf
*.bash text eol=lf
*.py text eol=lf
*.yaml text eol=lf
*.yml text eol=lf

# Windows scripts — keep CRLF on Windows checkouts
*.ps1 text eol=crlf
*.psm1 text eol=crlf
*.psd1 text eol=crlf
*.bat text eol=crlf
*.cmd text eol=crlf

# Binary files — never touch line endings
*.pem binary
*.pfx binary
*.png binary
*.zip binary
```

A `.gitattributes` file committed to the repo ensures consistent line endings
regardless of each contributor's `core.autocrlf` setting. This prevents "entire file
changed" noise in diffs caused by line ending conversions.

---

## Common Pitfalls to Flag

- `git add .` without reviewing `git diff` first → use `git add -p`
- No `.gitignore` before first commit → check for secrets before adding one later
- Committing `.env`, `*-cred.xml`, or any `ConvertTo-SecureString` export → flag immediately
- `git commit -m "WIP"` on a shared branch → use stash or a feature branch instead
- `git push --force` (not `--force-with-lease`) → can silently overwrite others' work
- Committing `*.tfstate` or `.terraform/` → always in `.gitignore`
- Committing `*.log` files → always in `.gitignore`
- Binary files over 1MB without Git LFS → repository becomes slow to clone
- Merge commits on a personal/solo repo → use `pull --rebase` for cleaner history
- No `README.md` explaining what the repo is, what it requires, and how to use it
