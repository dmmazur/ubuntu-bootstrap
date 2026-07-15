# ubuntu-bootstrap

Ansible playbooks to set up a local Ubuntu workstation (apt, snaps,
local `.deb`s, and optional tools).

## Quick start (fresh Ubuntu)

```bash
git clone https://github.com/dmmazur/ubuntu-bootstrap.git
cd ubuntu-bootstrap

# Full install (Ansible + all enabled sections)
./bootstrap.sh

# Or one section at a time:
./scripts/bootstrap-common.sh
./scripts/bootstrap-snaps.sh
./scripts/bootstrap-debs.sh
./scripts/bootstrap-lmto.sh
```

Optional before running:

- Cursor / VeraCrypt `.deb` files in `files/` (see below)
- LMTO source tree at `~/src` (see [`files/LMTO.md`](files/LMTO.md))

Verbose Ansible output: `BOOTSTRAP_VERBOSE=1 ./bootstrap.sh`

### Manual ansible-playbook (alternative)

```bash
sudo apt update
sudo apt install -y ansible
ansible-galaxy collection install community.general

sudo --preserve-env=HOME \
  ansible-playbook playbook.yml --tags common -e ansible_become=false -v
```

Section banners (`>>> COMMON`, …) and per-package task names show progress.

### Install scripts

| Script | Section |
|--------|---------|
| `./bootstrap.sh` | Everything (enabled in `group_vars/all.yml`) |
| `./scripts/bootstrap-common.sh` | Common apt packages |
| `./scripts/bootstrap-lab.sh` | Lab apt packages |
| `./scripts/bootstrap-snaps.sh` | Snaps |
| `./scripts/bootstrap-debs.sh` | Cursor, VeraCrypt `.debs` |
| `./scripts/bootstrap-claude.sh` | Claude Desktop |
| `./scripts/bootstrap-chrome.sh` | Google Chrome |
| `./scripts/bootstrap-lmto.sh` | LMTO + Intel apt |
| `./scripts/bootstrap-flatpak.sh` | Flatpak (off by default) |
| `./scripts/bootstrap-ollama.sh` | Ollama (off by default) |

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
./scripts/bootstrap-common.sh
./scripts/bootstrap-common.sh --check --diff   # dry-run (passed to ansible-playbook)
BOOTSTRAP_VERBOSE=1 ./scripts/bootstrap-snaps.sh
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
