# ubuntu-bootstrap

Ansible playbooks to set up a local Ubuntu workstation (apt, snaps,
local `.deb`s, and optional tools).

## Quick start

```bash
sudo apt update
sudo apt install -y ansible
ansible-galaxy collection install community.general

# optional: download Cursor / VeraCrypt .debs into files/ (see below)

# Prefer this if become/password prompts time out on this machine:
sudo --preserve-env=HOME \
  ansible-playbook playbook.yml --tags common -e ansible_become=false

# More Ansible detail:
sudo --preserve-env=HOME \
  ansible-playbook playbook.yml --tags common -e ansible_become=false -v
```

Section banners (`>>> COMMON`, …) and per-package task names show progress.

## Tags

| Tag | What it installs |
|-----|------------------|
| `common` | Shared apt packages (includes `gh`) |
| `lab` | NFS, gv, emacs, terminals, etc. (`enable_lab_packages`) |
| `snaps` | VS Code, Telegram, Claude Code |
| `flatpak` | Flathub + Newelle, Flatseal (`install_flatpak`, currently off) |
| `debs` | Cursor, VeraCrypt from `files/` |
| `claude` | Claude Desktop apt repo + package |
| `chrome` | Google Chrome apt repo + package |
| `ollama` | Ollama tarball + systemd (`install_ollama`, currently off) |
| `lmto` | LMTO stack: apt deps, Intel oneAPI, env, NFS, configure/make |

Examples:

```bash
ansible-playbook playbook.yml --ask-become-pass --tags common,snaps
ansible-playbook playbook.yml --ask-become-pass --skip-tags ollama,lab
ansible-playbook playbook.yml --ask-become-pass --tags lmto
```

## Layout

| Path | Purpose |
|------|---------|
| `ansible.cfg` | Defaults (local inventory, become) |
| `inventory.ini` | `localhost` with local connection |
| `playbook.yml` | Bootstrap tasks |
| `group_vars/all.yml` | Package lists, toggles, LMTO options |
| `files/` | Local `.deb`s (not committed) |
| `roles/lmto/` | LMTO install role (prereqs → Intel apt → env → build) |

## LMTO

Separate step (`install_lmto: true`, tag `lmto`). See [`files/LMTO.md`](files/LMTO.md).

- **Source:** already at `~/src` (copy, rsync, or symlink from the other machine)
- **Intel:** apt via Intel oneAPI repo — `intel-oneapi-compiler-fortran` + `intel-oneapi-mkl-devel`
- Then: apt deps → oneAPI → env → optional NFS → `./configure` + `make` in `~/src`

```bash
sudo --preserve-env=HOME \
  ansible-playbook playbook.yml --tags lmto -e ansible_become=false

# Prep only (no compile): set lmto_build: false in group_vars
```

## Local `.deb` downloads

Place installers under `files/` (details in [`files/README.md`](files/README.md)):

| Package | Where to get it |
|---------|-----------------|
| **VeraCrypt** | https://veracrypt.io/en/Downloads.html — or direct amd64 builds from [GitHub 1.26.29](https://github.com/veracrypt/VeraCrypt/releases/tag/VeraCrypt_1.26.29) (pick your Ubuntu release, e.g. [26.04](https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_1.26.29/veracrypt-1.26.29-Ubuntu-26.04-amd64.deb) / [24.04](https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_1.26.29/veracrypt-1.26.29-Ubuntu-24.04-amd64.deb)) |
| **Cursor** | https://cursor.com/download — choose the Linux **DEB** (latest version every time) |

```bash
# VeraCrypt example (Ubuntu 26.04 amd64)
curl -fLO --output-dir files \
  https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_1.26.29/veracrypt-1.26.29-Ubuntu-26.04-amd64.deb

# Cursor: download the .deb from the site, then:
cp ~/Downloads/cursor_*.deb files/
```

## Branches

- `main` — stable scaffold
- `develop` — work in progress
