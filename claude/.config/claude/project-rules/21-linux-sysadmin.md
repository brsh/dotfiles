---
trigger: always_on
---

# Linux Sysadmin Context

This file provides context about the Linux environments I work in. Apply this
knowledge when generating scripts, commands, and recommendations.

---

## Environment Context

- **Primary distros**: RHEL 8/9 and Rocky Linux 8/9 (enterprise primary)
- **Secondary**: Ubuntu 22.04 LTS / 24.04 LTS (some workloads, WSL2)
- **Personal/lab**: Arch Linux and derivatives (Manjaro, EndeavourOS, CachyOS)
- **Init system**: systemd on all modern systems
- **Configuration management**: Ansible (primary automation tool)
- **Containers**: Podman (RHEL/Rocky preferred), Docker (Ubuntu/dev)
- **Shell**: Bash scripts, occasional Python for complex automation

---

## Package Management

```bash
# RHEL/Rocky 8/9
dnf install <package>
dnf update
dnf search <keyword>
dnf info <package>
rpm -qa | grep <name>           # list installed packages matching name
rpm -qf /path/to/file           # which package owns this file

# Ubuntu/Debian
apt-get update && apt-get install -y <package>
apt-cache search <keyword>
dpkg -l | grep <name>
dpkg -S /path/to/file           # which package owns this file
```

For scripts targeting multiple distro families, check and branch:

```bash
if command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
elif command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt-get"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
else
    die "No supported package manager found"
fi
```

---

## Arch Linux / pacman

Arch and its derivatives (Manjaro, EndeavourOS, CachyOS, Garuda, ArcoLinux) use
`pacman` as the package manager and follow a **rolling release** model — there are
no major version upgrades; the system stays current through continuous updates.

### Package Management

```bash
# Core pacman operations
pacman -Syu                     # sync and upgrade all packages (do this regularly)
pacman -S <package>             # install
pacman -Rs <package>            # remove package and unneeded dependencies
pacman -Ss <keyword>            # search repositories
pacman -Si <package>            # package info from repos
pacman -Qi <package>            # package info from installed
pacman -Ql <package>            # list files owned by package
pacman -Qo /path/to/file        # which package owns a file
pacman -Qdt                     # list orphaned packages (no longer needed)
pacman -Sc                      # clear package cache (old versions)
```

### AUR (Arch User Repository)

The AUR hosts community-maintained packages not in the official repos. **Never run
an AUR helper as root.** Review the `PKGBUILD` before building anything from the AUR.

```bash
# yay (common AUR helper — same interface as pacman)
yay -Syu                        # update official + AUR packages
yay -S <aur-package>
yay -Ss <keyword>               # search official + AUR

# paru (Rust-based AUR helper, stricter security defaults)
paru -Syu
paru -S <aur-package>

# Manual AUR build (no helper)
git clone https://aur.archlinux.org/package.git
cd package
cat PKGBUILD                    # always review before building
makepkg -si                     # build and install
```

**Security note**: AUR packages are community-maintained and not vetted by Arch.
Always read the `PKGBUILD` before installing. Flag AUR installs in scripts.

### Arch-Specific Paths and Conventions

```bash
# Package cache (large over time — clean regularly)
/var/cache/pacman/pkg/

# Pacman configuration
/etc/pacman.conf                # repos, options, ignored packages
/etc/pacman.d/mirrorlist        # mirror priority (use reflector to update)

# Reflector — update mirrors by speed/country
reflector --country US,CA --age 12 --sort rate --save /etc/pacman.d/mirrorlist

# pacman.conf — useful options
# Color           # colored output
# ParallelDownloads = 5
# IgnorePkg = linux linux-headers  # hold specific packages from upgrade
```

### Arch vs RHEL/Ubuntu Differences to Flag in Scripts

| Item | RHEL/Rocky | Ubuntu | Arch |
|------|-----------|--------|------|
| Package manager | `dnf` / `rpm` | `apt-get` / `dpkg` | `pacman` |
| Service user group | `wheel` (sudo) | `sudo` | `wheel` |
| SELinux | Enforcing (default) | Not installed | Not installed |
| AppArmor | Not default | Available | Available (optional) |
| Log tool | `journalctl` + `/var/log/messages` | `journalctl` + `/var/log/syslog` | `journalctl` only |
| Release model | Point releases | Point releases | Rolling |
| Kernel updates | Controlled, tested | LTS kernel | Latest stable |

### Rolling Release Considerations

- **Update frequently** — letting Arch go unupdated for months creates large, risky updates.
  Prefer `pacman -Syu` weekly in lab/personal environments.
- **Check the Arch news** (`https://archlinux.org/news/`) before major updates — manual
  intervention is occasionally required for breaking changes.
- **Manjaro holds updates** briefly for testing; EndeavourOS ships upstream Arch packages
  with minimal delay. CachyOS uses performance-tuned kernels.
- **No SELinux by default** — AppArmor is available but not enabled by default on most
  Arch installs. Do not assume MAC enforcement is active.
- Rolling release is appropriate for **personal/lab systems**, not production servers.
  Use RHEL/Rocky for production.

### Manjaro-Specific Notes

```bash
# Manjaro uses pamac (GUI) and mhwd (hardware detection)
pamac install <package>         # Manjaro's pacman wrapper
pamac update
mhwd -l                         # list available hardware drivers
mhwd -i pci video-nvidia        # install NVIDIA driver

# Manjaro holds packages in 'stable' / 'testing' / 'unstable' branches
sudo pacman-mirrors --fasttrack 5 && sudo pacman -Syyu
```

---

## systemd Service Management

```bash
# Status and logs
systemctl status nginx
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx -n 100 --no-pager
journalctl -f                   # follow all logs (like tail -f syslog)

# Control
systemctl start|stop|restart|reload nginx
systemctl enable|disable nginx   # enable = start at boot
systemctl daemon-reload          # required after editing unit files

# List units
systemctl list-units --state=failed
systemctl list-units --type=service --state=running
```

### Writing Systemd Unit Files

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/bin/myapp --config /etc/myapp/config.yaml
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
# Security hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/myapp /var/log/myapp

[Install]
WantedBy=multi-user.target
```

Always use a dedicated service account (`User=myapp`), never run services as root.
Add security directives (`NoNewPrivileges`, `ProtectSystem`, etc.) for new services.

---

## Networking

```bash
# Preferred modern tools (NOT ifconfig/netstat — those are deprecated)
ip addr show                    # interface addresses
ip route show                   # routing table
ip link show                    # interface state
ss -tlnp                        # listening TCP sockets with PIDs
ss -ulnp                        # listening UDP sockets
ss -s                           # socket statistics summary

# DNS
dig +short hostname.example.com
dig @8.8.8.8 hostname.example.com   # query specific nameserver
resolvectl status               # systemd-resolved status (Ubuntu)

# Connectivity tests
ping -c 4 host
traceroute host                 # or tracepath (no root needed)
curl -I https://host            # HTTP response headers only
nc -zv host port                # test TCP port connectivity

# RHEL/Rocky — NetworkManager
nmcli device status
nmcli connection show
nmcli connection modify "ens192" ipv4.addresses "10.0.0.10/24"
nmcli connection up "ens192"
```

---

## Firewall Management

```bash
# RHEL/Rocky — firewalld (preferred)
firewall-cmd --list-all                          # current config
firewall-cmd --zone=public --add-port=443/tcp    # temporary (until next reload)
firewall-cmd --zone=public --add-port=443/tcp --permanent  # persistent
firewall-cmd --reload                            # apply permanent rules
firewall-cmd --zone=public --list-ports

# Ubuntu — ufw
ufw status verbose
ufw allow 443/tcp
ufw allow from 10.0.0.0/24 to any port 22
ufw enable
```

---

## SELinux (RHEL/Rocky — important)

**Do not disable SELinux in production.** If something fails due to SELinux, fix
the policy — don't `setenforce 0`.

```bash
# Check status
getenforce                      # Enforcing / Permissive / Disabled
sestatus

# Troubleshoot denials
ausearch -m avc -ts recent      # recent AVC denials
sealert -a /var/log/audit/audit.log  # human-readable analysis

# Common fixes
# Wrong file context
restorecon -Rv /path/to/directory
semanage fcontext -a -t httpd_sys_content_t "/myapp/html(/.*)?"
restorecon -Rv /myapp/html

# Service needs to bind a non-standard port
semanage port -a -t http_port_t -p tcp 8443

# Allow a boolean
getsebool -a | grep httpd
setsebool -P httpd_can_network_connect on   # -P makes it persistent
```

---

## User and Permission Management

```bash
# User management
useradd -r -s /sbin/nologin -d /opt/myapp -c "MyApp Service Account" myapp
usermod -aG wheel username       # add to sudo group (RHEL/Rocky)
usermod -aG sudo username        # add to sudo group (Ubuntu)
passwd -l username               # lock account
chage -l username                # view password aging info
chage -E 2025-12-31 username     # set account expiry

# File permissions
chmod 750 /opt/myapp
chown -R myapp:myapp /opt/myapp
setfacl -m u:nginx:rx /opt/myapp/html    # ACL for specific user without changing owner

# sudo configuration
visudo                           # always use visudo, never edit sudoers directly
# /etc/sudoers.d/myapp
myapp ALL=(root) NOPASSWD: /usr/bin/systemctl restart myapp
```

---

## Log Management

```bash
# journald (systemd logs)
journalctl -u service_name --since "2024-01-01" --until "2024-01-02"
journalctl -p err -n 50          # last 50 error-level entries
journalctl --disk-usage
journalctl --vacuum-time=30d     # remove logs older than 30 days

# Traditional log locations
/var/log/messages                # RHEL/Rocky — general system log
/var/log/syslog                  # Ubuntu — general system log
/var/log/secure                  # RHEL/Rocky — auth log
/var/log/auth.log                # Ubuntu — auth log
/var/log/audit/audit.log         # SELinux and audit events

# Logrotate
/etc/logrotate.d/myapp           # per-app logrotate config
logrotate -d /etc/logrotate.d/myapp  # dry run
```

---

## SSH Hardening (flag these when writing SSH configs)

Recommended `/etc/ssh/sshd_config` settings for servers:

```
PermitRootLogin no
PasswordAuthentication no        # keys only — requires key distribution first
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers admin svcaccount      # whitelist where appropriate
```

After changes: `sshd -t` to test config, then `systemctl reload sshd`.

---

## Cron and Scheduled Tasks

```bash
# User crontab
crontab -e        # edit
crontab -l        # list
crontab -l -u username   # view another user's crontab

# System cron
/etc/crontab
/etc/cron.d/myapp    # preferred for system tasks (includes username field)

# Format: minute hour day-of-month month day-of-week user command
# 0 2 * * * root /opt/scripts/backup.sh >> /var/log/backup.log 2>&1
```

Prefer **systemd timers** over cron for new services — they integrate with journald
and have better dependency management:

```bash
# /etc/systemd/system/myapp-backup.timer
[Timer]
OnCalendar=daily
Persistent=true

# Create a matching myapp-backup.service unit for the actual command
```

---

## Common Pitfalls to Flag

- `setenforce 0` or `SELINUX=disabled` in `/etc/selinux/config` → flag, suggest fixing policy
- Running services as root → suggest dedicated service account
- `chmod 777` → flag, suggest minimal required permissions
- `PasswordAuthentication yes` in sshd_config → suggest key-based auth
- Editing `/etc/sudoers` directly → use `visudo` or `/etc/sudoers.d/`
- `wget ... | bash` patterns → flag as security risk
- `curl http://` (not https) for package installs → flag
- No log rotation configured for custom app logs → suggest logrotate config
- `netstat` or `ifconfig` → suggest `ss` and `ip` respectively
- Direct edits to network config files without using NetworkManager → suggest `nmcli`
- AUR installs without reviewing `PKGBUILD` → flag as security risk
- Running `yay`/`paru` as root → never; AUR helpers must run as normal user
- Letting Arch go months without updates → flag, suggest regular `pacman -Syu`
- Assuming SELinux is enforcing on Arch/Manjaro systems → it's not installed by default
