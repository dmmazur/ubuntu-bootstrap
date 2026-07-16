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
./scripts/bootstrap-lab.sh
./scripts/bootstrap-snaps.sh
./scripts/bootstrap-claude.sh
./scripts/bootstrap-chrome.sh
./scripts/bootstrap-lmto.sh
# ./scripts/bootstrap-debs.sh   # off by default (install_debs: false)
```

Optional before running:

- LMTO source tree at `~/src` (see [`files/LMTO.md`](files/LMTO.md))
- Cursor / VeraCrypt `.deb` files in `files/` only if you set `install_debs: true`

Verbose Ansible output: `BOOTSTRAP_VERBOSE=1 ./bootstrap.sh`

### Current toggles (`group_vars/all.yml`)

| Toggle | Default | Section |
|--------|---------|---------|
| *(always)* | on | `common`, `snaps` |
| `enable_lab_packages` | `true` | `lab` |
| `install_claude_desktop` | `true` | `claude` |
| `install_google_chrome` | `true` | `chrome` |
| `install_lmto` | `true` | `lmto` |
| `lmto_nfs_enable` | `false` | NFS mount + `/dep24` convenience links |
| `install_debs` | `false` | Cursor / VeraCrypt from `files/` |
| `install_flatpak` | `false` | Flatpak apps |
| `install_ollama` | `false` | Ollama |

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
| `./scripts/bootstrap-debs.sh` | Cursor, VeraCrypt `.debs` (`install_debs`, currently off) |
| `./scripts/bootstrap-claude.sh` | Claude Desktop |
| `./scripts/bootstrap-chrome.sh` | Google Chrome |
| `./scripts/bootstrap-lmto.sh` | LMTO + Intel apt |
| `./scripts/bootstrap-flatpak.sh` | Flatpak (`install_flatpak`, currently off) |
| `./scripts/bootstrap-ollama.sh` | Ollama (`install_ollama`, currently off) |

### Verify what is installed

Read expectations from `group_vars/all.yml` and report **OK / MISSING / SKIP** (no Ansible). Exit `1` if anything expected is missing.

```bash
./verify-installed.sh              # all sections
./scripts/verify-common.sh
./scripts/verify-lab.sh
./scripts/verify-snaps.sh
./scripts/verify-lmto.sh           # Intel, ~/src, binaries, profile, scratch, symlinks, NFS
./scripts/verify-claude.sh
./scripts/verify-chrome.sh
./scripts/verify-debs.sh           # SKIP when install_debs is false
./scripts/verify-flatpak.sh
./scripts/verify-ollama.sh
```

| Script | Checks |
|--------|--------|
| `./verify-installed.sh` | Full inventory status |
| `./scripts/verify-common.sh` | Common apt packages |
| `./scripts/verify-lab.sh` | Lab apt packages |
| `./scripts/verify-snaps.sh` | Snap packages |
| `./scripts/verify-debs.sh` | Cursor / VeraCrypt |
| `./scripts/verify-claude.sh` | Claude Desktop + apt repo files |
| `./scripts/verify-chrome.sh` | Chrome + apt repo files |
| `./scripts/verify-lmto.sh` | LMTO apt/Intel/`~/src`/binaries/links/NFS |
| `./scripts/verify-flatpak.sh` | Flatpak apps |
| `./scripts/verify-ollama.sh` | Ollama binary + systemd |

### Gather LaTeX setup (from a machine that already has it)

Run on the **old** workstation, then copy the report to this repo / new PC:

```bash
./scripts/gather-latex-setup.sh
./scripts/gather-latex-setup.sh --archive   # also pack ~/texmf + latexmkrc
```

Writes `~/Downloads/latex-setup-report-*.txt` (plus optional `*-userdata.tgz` and tlmgr list).

### Gather LMTO setup (from a machine that already has it)

Run on the **old** workstation (probes filesystem + configs; history is usage-only):

```bash
./scripts/gather-lmto-setup.sh
./scripts/gather-lmto-setup.sh --archive   # also pack lmt, systemoptions, localoptions
```

Writes `~/Downloads/lmto-setup-report-*.txt`. Copy `~/src` separately via rsync.

## Tags

| Tag | What it installs |
|-----|------------------|
| `common` | Shared apt packages (includes `gh`) |
| `lab` | NFS, gv, emacs, terminals, etc. (`enable_lab_packages`) |
| `snaps` | VS Code, Telegram, Claude Code |
| `flatpak` | Flathub + Newelle, Flatseal (`install_flatpak`, currently off) |
| `debs` | Cursor, VeraCrypt from `files/` (`install_debs`, currently off) |
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
| `bootstrap.sh` | Full first-time install entrypoint |
| `verify-installed.sh` | Full install-status check (no Ansible) |
| `ansible.cfg` | Defaults (local inventory, become) |
| `inventory.ini` | `localhost` with local connection |
| `playbook.yml` | Bootstrap tasks |
| `group_vars/all.yml` | Package lists, toggles, LMTO options |
| `scripts/lib.sh` | Shared helpers for bootstrap-*.sh |
| `scripts/verify-lib.sh` | Shared helpers for verify-*.sh |
| `scripts/bootstrap-*.sh` | Per-section install scripts |
| `scripts/verify-*.sh` | Per-section status checks |
| `files/` | Optional local `.deb`s (not committed; used when `install_debs: true`) |
| `files/LMTO.md` | LMTO source + Intel apt notes |
| `roles/lmto/` | LMTO install role (prereqs → Intel apt → env → build) |

## LMTO

Separate step (`install_lmto: true`, tag `lmto`). See [`files/LMTO.md`](files/LMTO.md).

- **Source:** already at `~/src` (copy, rsync, or symlink from the other machine)
- **Intel:** apt via Intel oneAPI repo — `intel-oneapi-compiler-fortran` + `intel-oneapi-mkl-devel`
- Then: apt deps → oneAPI → env → optional NFS → `./configure` + `make` in `~/src`
- **NFS** (`lmto_nfs_enable`) defaults to **false** — `/dep24` home symlinks are created only when those targets exist

```bash
./scripts/bootstrap-lmto.sh
./scripts/verify-lmto.sh

# Or Ansible directly:
sudo --preserve-env=HOME \
  ansible-playbook playbook.yml --tags lmto -e ansible_become=false

# Prep only (no compile): set lmto_build: false in group_vars
```

## Local `.deb` downloads

Currently **disabled** (`install_debs: false`). To use them, set `install_debs: true` and place installers under `files/` (details in [`files/README.md`](files/README.md)):

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
