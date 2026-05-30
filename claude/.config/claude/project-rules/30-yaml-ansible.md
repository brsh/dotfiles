---
trigger: glob
glob: "**/*.{yml,yaml}"
description: "YAML and Ansible best practices for infrastructure automation"
---

# YAML and Ansible Rules

---

## YAML Style

- **2-space indentation** — never tabs
- **Quote strings** that could be misread as other types:
  ```yaml
  # Quote these
  version: "1.0"          # would be a float without quotes
  enabled: "yes"          # would be boolean without quotes
  port: "8080"            # quote if you need a string, omit if integer is correct
  octal: "0755"           # quote octal-looking strings
  ```
- Use **block style** (`|` or `>`) for multi-line strings rather than `\n` escaping:
  ```yaml
  message: |
    This is a multi-line
    message that preserves
    newlines.

  command: >
    /usr/bin/long-command
    --with-lots-of-flags
    --and-arguments
  ```
- Keep lines under 120 characters
- Use consistent quoting style within a file

---

## Ansible Playbook Structure

### Directory Layout (Ansible Best Practice)

```
ansible/
├── ansible.cfg             # project-level config (inventory path, vault ID, etc.)
├── inventory/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   │       ├── all.yml
│   │       ├── webservers.yml
│   │       └── dbservers.yml
│   └── staging/
│       └── hosts.yml
├── playbooks/
│   ├── site.yml            # master playbook (imports all roles)
│   ├── webservers.yml
│   └── patching.yml
├── roles/
│   └── nginx/
│       ├── tasks/main.yml
│       ├── handlers/main.yml
│       ├── templates/nginx.conf.j2
│       ├── files/
│       ├── vars/main.yml
│       ├── defaults/main.yml   # overridable defaults
│       └── meta/main.yml
└── requirements.yml        # Ansible Galaxy roles/collections
```

### Playbook Template

```yaml
---
- name: Configure web servers            # always name your play
  hosts: webservers
  become: true
  gather_facts: true

  vars:
    nginx_port: 80
    nginx_user: nginx

  pre_tasks:
    - name: Ensure required variables are defined
      ansible.builtin.assert:
        that:
          - nginx_port is defined
          - nginx_port | int > 0
        fail_msg: "nginx_port must be a positive integer"

  roles:
    - nginx

  post_tasks:
    - name: Verify nginx is responding
      ansible.builtin.uri:
        url: "http://localhost:{{ nginx_port }}"
        status_code: 200
```

---

## Task Writing Rules

### Always Name Every Task

```yaml
# Good
- name: Install nginx web server
  ansible.builtin.dnf:
    name: nginx
    state: present

# Bad — impossible to identify in logs
- ansible.builtin.dnf:
    name: nginx
    state: present
```

### Use Fully Qualified Collection Names (FQCN)

```yaml
# Good — explicit, no ambiguity, future-proof
ansible.builtin.copy:
ansible.builtin.template:
ansible.builtin.service:
ansible.posix.firewalld:
community.general.npm:

# Acceptable for shorthand in known contexts
# but FQCN is preferred in shared/production playbooks
```

### Idempotency — Tasks Must Be Safe to Run Multiple Times

Every task should produce the same result whether run once or ten times:

```yaml
# Good — idempotent (state: present means "ensure it exists")
- name: Create application directory
  ansible.builtin.file:
    path: /opt/myapp
    state: directory
    owner: myapp
    group: myapp
    mode: "0750"

# Good — idempotent line in file
- name: Ensure kernel parameter is set
  ansible.builtin.lineinfile:
    path: /etc/sysctl.conf
    regexp: '^vm.swappiness'
    line: 'vm.swappiness=10'
    state: present
  notify: Apply sysctl settings

# Bad — not idempotent (appends every time)
- name: Add kernel parameter
  ansible.builtin.shell: echo 'vm.swappiness=10' >> /etc/sysctl.conf
```

---

## Handlers

Use handlers for service restarts triggered by config changes:

```yaml
# In tasks/main.yml
- name: Deploy nginx configuration
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: "0644"
    validate: nginx -t -c %s
  notify: Restart nginx

# In handlers/main.yml
- name: Restart nginx
  ansible.builtin.service:
    name: nginx
    state: restarted

- name: Reload nginx
  ansible.builtin.service:
    name: nginx
    state: reloaded
```

Handlers only run once at the end of a play, even if notified multiple times.
Use `reload` over `restart` where the service supports it — avoids dropped connections.

---

## Error Handling

```yaml
# block/rescue/always for complex error handling
- name: Deploy application
  block:
    - name: Stop application service
      ansible.builtin.service:
        name: myapp
        state: stopped

    - name: Deploy new version
      ansible.builtin.unarchive:
        src: "{{ artifact_url }}"
        dest: /opt/myapp
        remote_src: true

    - name: Start application service
      ansible.builtin.service:
        name: myapp
        state: started

  rescue:
    - name: Log deployment failure
      ansible.builtin.debug:
        msg: "Deployment failed — rolling back"

    - name: Restore previous version
      ansible.builtin.copy:
        src: /opt/myapp-backup/
        dest: /opt/myapp/
        remote_src: true

  always:
    - name: Ensure service is running regardless
      ansible.builtin.service:
        name: myapp
        state: started
```

---

## Secrets with Ansible Vault

```bash
# Encrypt a variable file
ansible-vault encrypt group_vars/production/vault.yml

# Encrypt a single string (for embedding in plaintext files)
ansible-vault encrypt_string 'MySecretPassword' --name 'db_password'

# Run playbook with vault password
ansible-playbook site.yml --vault-password-file ~/.vault_pass
ansible-playbook site.yml --ask-vault-pass
```

Variable file pattern — keep vault variables separate:

```yaml
# group_vars/production/vars.yml (not encrypted — safe to commit)
db_user: appuser
db_host: db01.internal
db_password: "{{ vault_db_password }}"   # references vault variable

# group_vars/production/vault.yml (encrypted — commit encrypted file)
vault_db_password: "ActualPasswordHere"
```

Never commit unencrypted secrets. Never put secrets in playbooks directly.

---

## Tags

Use tags to allow selective execution:

```yaml
- name: Install packages
  ansible.builtin.dnf:
    name: "{{ item }}"
    state: present
  loop: "{{ required_packages }}"
  tags:
    - packages
    - install

- name: Deploy configuration
  ansible.builtin.template:
    src: app.conf.j2
    dest: /etc/myapp/app.conf
  tags:
    - config
    - deploy
```

```bash
ansible-playbook site.yml --tags "config"          # run only config tasks
ansible-playbook site.yml --skip-tags "install"    # skip install tasks
```

---

## Testing and Validation

```bash
# Syntax check
ansible-playbook site.yml --syntax-check

# Dry run (check mode)
ansible-playbook site.yml --check

# Check + show diffs
ansible-playbook site.yml --check --diff

# Lint (install: pip install ansible-lint)
ansible-lint site.yml
ansible-lint roles/nginx/

# Run against a single host for testing
ansible-playbook site.yml --limit web01.example.com
```

**Always run `--check --diff` against production before a real apply.**

---

## Variables and Precedence

Ansible variable precedence (highest wins):
1. Extra vars (`-e "var=value"`) — highest
2. Task vars
3. Block vars
4. Play vars
5. Host vars (`host_vars/hostname.yml`)
6. Group vars (`group_vars/groupname.yml`)
7. Role defaults (`roles/myrole/defaults/main.yml`) — lowest

Use `defaults/main.yml` in roles for values users should be able to override.
Use `vars/main.yml` for values that should not normally be overridden.

---

## Common Pitfalls to Flag

- Task without a `name:` field → always add a descriptive name
- Using `shell:` or `command:` for something a module can do natively → prefer modules
- Not using `--check` before production apply → always suggest dry run first
- Hardcoded IPs or hostnames in tasks → use inventory variables
- `state: latest` in package installs → can cause unexpected upgrades; use `state: present`
  unless upgrading is the intent
- No `validate:` on config file templates → suggest adding config validation
- Service restart in a task directly → use handlers instead
- Secrets in plaintext in vars files → use ansible-vault
- Missing `become: true` for tasks that need root → will silently fail or error
