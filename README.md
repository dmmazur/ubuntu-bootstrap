# ubuntu-bootstrap

Ansible playbooks to set up a local Ubuntu workstation (apt, snaps, flatpaks, local `.deb`s, optional lab tools).

## Quick start

```bash
sudo apt update
sudo apt install -y ansible
ansible-galaxy collection install community.general

ansible-playbook playbook.yml --ask-become-pass
```

## Layout

| Path | Purpose |
|------|---------|
| `ansible.cfg` | Defaults (local inventory, become) |
| `inventory.ini` | `localhost` with local connection |
| `playbook.yml` | Main bootstrap play |
| `group_vars/all.yml` | Package lists and toggles |
| `roles/` | Roles (added later) |
| `files/` | Local installers / `.deb`s (added later) |

## Branches

- `main` — stable
- `develop` — work in progress
