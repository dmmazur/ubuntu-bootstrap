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
./scripts/bootstrap/bootstrap-common.sh
./scripts/bootstrap/bootstrap-lab.sh
./scripts/bootstrap/bootstrap-latex.sh
./scripts/bootstrap/bootstrap-snaps.sh
./scripts/bootstrap/bootstrap-claude.sh
./scripts/bootstrap/bootstrap-chrome.sh
./scripts/bootstrap/bootstrap-dotnet.sh
./scripts/bootstrap/bootstrap-lmto.sh
# ./scripts/bootstrap/bootstrap-debs.sh   # off by default (install_debs: false)
```

Optional before running:

- LMTO archives `lmto5.04.6.tar.gz` + `lmto5.04.6p.tar.gz` in `files/` (or `~/Downloads` / `~/src`) — see [`files/LMTO.md`](files/LMTO.md)
- Optional LaTeX userdata: `files/latex-userdata.tgz` from gather script — see [`files/LATEX.md`](files/LATEX.md)
- Cursor / VeraCrypt `.deb` files in `files/` only if you set `install_debs: true`

Verbose Ansible output: `BOOTSTRAP_VERBOSE=1 ./bootstrap.sh`

### Troubleshooting

If a section fails (especially on **WSL2**), see [`troubleshooting/`](troubleshooting/README.md) — DNS/vendor repos, Intel apt poisoning later runs, snaps, LMTO `ifx` PATH, setvars warnings, clock skew, VS Code on WSL.

### Current toggles (`group_vars/all.yml`)

| Toggle | Default | Section |
|--------|---------|---------|
| *(always)* | on | `common`, `snaps` |
| `enable_lab_packages` | `true` | `lab` |
| `install_latex` | `true` | `latex` (self-contained TeX Live apt) |
| `install_latex_editors` | `true` | `latex-editors` (LaTeX Workshop for Cursor/VS Code) |
| `install_claude_desktop` | `true` | `claude` |
| `install_google_chrome` | `true` | `chrome` |
| `install_dotnet_sdk` | `true` | `dotnet` (.NET 8 SDK via Ubuntu apt) |
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

**Command logs:** each `./scripts/bootstrap/*.sh` run writes under a temp dir (`/tmp/ubuntu-bootstrap.XXXXXX`), also linked as `/tmp/ubuntu-bootstrap-latest`. Includes `playbook.log` (full console), `ansible.log` (Ansible detail), and per-command files such as `apt-*.log`, `configure.log`, `make.log`, `lmt-Fe.log`.

### Install scripts

| Script | Section |
|--------|---------|
| `./bootstrap.sh` | Everything (enabled in `group_vars/all.yml`) |
| `./scripts/bootstrap/bootstrap-common.sh` | Common apt packages |
| `./scripts/bootstrap/bootstrap-lab.sh` | Lab apt packages |
| `./scripts/bootstrap/bootstrap-latex.sh` | LaTeX (all phases; self-contained) |
| `./scripts/bootstrap/bootstrap-latex.sh apt` | TeX Live apt packages only |
| `./scripts/bootstrap/bootstrap-latex.sh texmf` | `~/texmf` + optional userdata archive |
| `./scripts/bootstrap/bootstrap-latex.sh smoke` | pdflatex smoke test |
| `./scripts/bootstrap/bootstrap-latex-editors.sh` | LaTeX Workshop → Cursor + VS Code |
| `./scripts/bootstrap/bootstrap-snaps.sh` | Snaps |
| `./scripts/bootstrap/bootstrap-debs.sh` | Cursor, VeraCrypt `.debs` (`install_debs`, currently off) |
| `./scripts/bootstrap/bootstrap-claude.sh` | Claude Desktop |
| `./scripts/bootstrap/bootstrap-chrome.sh` | Google Chrome |
| `./scripts/bootstrap/bootstrap-dotnet.sh` | .NET 8 SDK (`dotnet-sdk-8.0`) |
| `./scripts/bootstrap/bootstrap-lmto.sh` | LMTO (all phases) |
| `./scripts/bootstrap/bootstrap-lmto.sh intel` | Intel apt + bashrc only |
| `./scripts/bootstrap/bootstrap-lmto.sh unpack` | `~/src` + unpack archives |
| `./scripts/bootstrap/bootstrap-lmto.sh rdir` | Create `~/R` (LMTO cases) |
| `./scripts/bootstrap/bootstrap-lmto.sh build` | configure + make |
| `./scripts/bootstrap/bootstrap-lmto.sh xscr` | copy Xscr, grf2eps, grfonts |
| `./scripts/bootstrap/bootstrap-lmto.sh test` | Fe smoke test: wipe `~/R/Fe` + bare `lmt` |
| `./scripts/bootstrap/bootstrap-lmto.sh ownership` | chown `~/src` `~/bin` `~/lib` → login user |
| `./scripts/bootstrap/bootstrap-flatpak.sh` | Flatpak (`install_flatpak`, currently off) |
| `./scripts/bootstrap/bootstrap-ollama.sh` | Ollama (`install_ollama`, currently off) |

### Verify what is installed

Read expectations from `group_vars/all.yml` and report **OK / MISSING / SKIP** (no Ansible). Exit `1` if anything expected is missing.

```bash
./verify-installed.sh              # all sections
./scripts/verify/verify-common.sh
./scripts/verify/verify-lab.sh
./scripts/verify/verify-latex.sh
./scripts/verify/verify-latex-editors.sh
./scripts/verify/verify-snaps.sh
./scripts/verify/verify-lmto.sh           # Intel, ~/src, binaries, profile, scratch, symlinks, NFS
./scripts/verify/verify-claude.sh
./scripts/verify/verify-chrome.sh
./scripts/verify/verify-dotnet.sh
./scripts/verify/verify-debs.sh           # SKIP when install_debs is false
./scripts/verify/verify-flatpak.sh
./scripts/verify/verify-ollama.sh
```

| Script | Checks |
|--------|--------|
| `./verify-installed.sh` | Full inventory status |
| `./scripts/verify/verify-common.sh` | Common apt packages |
| `./scripts/verify/verify-lab.sh` | Lab apt packages |
| `./scripts/verify/verify-latex.sh` | TeX Live apt / `pdflatex` / `~/texmf` / smoke.pdf |
| `./scripts/verify/verify-latex-editors.sh` | LaTeX Workshop in Cursor / VS Code |
| `./scripts/verify/verify-snaps.sh` | Snap packages |
| `./scripts/verify/verify-debs.sh` | Cursor / VeraCrypt |
| `./scripts/verify/verify-claude.sh` | Claude Desktop + apt repo files |
| `./scripts/verify/verify-chrome.sh` | Chrome + apt repo files |
| `./scripts/verify/verify-dotnet.sh` | .NET SDK apt package + `dotnet` CLI |
| `./scripts/verify/verify-lmto.sh` | LMTO apt/Intel/`~/src`/binaries/links/NFS |
| `./scripts/verify/verify-flatpak.sh` | Flatpak apps |
| `./scripts/verify/verify-ollama.sh` | Ollama binary + systemd |

### Gather LaTeX setup (from a machine that already has it)

Run on the **old** workstation, then copy the report to this repo / new PC:

```bash
./scripts/gather/gather-latex-setup.sh
./scripts/gather/gather-latex-setup.sh --archive   # also pack ~/texmf + latexmkrc
```

Writes `~/Downloads/latex-setup-report-*.txt` (plus optional `*-userdata.tgz` and tlmgr list).

### Gather LMTO setup (from a machine that already has it)

Run on the **old** workstation (probes filesystem + configs; history is usage-only):

```bash
./scripts/gather/gather-lmto-setup.sh
./scripts/gather/gather-lmto-setup.sh --archive   # also pack lmt, systemoptions, localoptions
```

Writes `~/Downloads/lmto-setup-report-*.txt`. Copy `~/src` separately via rsync.

## Tags

| Tag | What it installs |
|-----|------------------|
| `common` | Shared apt packages (includes `gh`) |
| `lab` | NFS, gv, emacs, terminals, etc. (`enable_lab_packages`) |
| `latex` | Full LaTeX stack (self-contained; phases below) |
| `latex-apt` | Curated TeX Live apt packages (+ own apt update) |
| `latex-texmf` | `~/texmf` layout + optional `files/latex-userdata.tgz` |
| `latex-smoke` | `pdflatex` smoke test → `~/TeX/smoke/smoke.pdf` |
| `latex-editors` | LaTeX Workshop extension for Cursor + VS Code |
| `snaps` | VS Code, Telegram, Claude Code |
| `flatpak` | Flathub + Newelle, Flatseal (`install_flatpak`, currently off) |
| `debs` | Cursor, VeraCrypt from `files/` (`install_debs`, currently off) |
| `claude` | Claude Desktop apt repo + package |
| `chrome` | Google Chrome apt repo + package |
| `dotnet` | .NET 8 SDK (`dotnet-sdk-8.0` from Ubuntu apt) |
| `ollama` | Ollama tarball + systemd (`install_ollama`, currently off) |
| `lmto` | Full LMTO stack (all phases below) |
| `lmto-intel` | Intel oneAPI apt + `~/.bashrc` LSYSTEM/setvars |
| `lmto-unpack` | Create `~/src`, unpack base + patch archives |
| `lmto-rdir` | Create `~/R` for LMTO cases |
| `lmto-build` | apt deps, configure, localoptions, make (optional `/scratch` if enabled) |
| `lmto-xscr` | Copy `SCRIPT/{Xscr,grf2eps,grfonts}` → `~/bin` + `~/bin/ifx` |
| `lmto-test` | Wipe `~/R/Fe`, run bare `lmt` structure setup |
| `lmto-ownership` | chown LMTO home paths to login user |

Examples:

```bash
./scripts/bootstrap/bootstrap-common.sh
./scripts/bootstrap/bootstrap-common.sh --check --diff   # dry-run (passed to ansible-playbook)
BOOTSTRAP_VERBOSE=1 ./scripts/bootstrap/bootstrap-snaps.sh
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
| `scripts/bootstrap/` | Install scripts + `lib.sh` |
| `scripts/verify/` | Status checks + `lib.sh` |
| `scripts/gather/` | Collect LaTeX/LMTO setup from an existing machine |
| `files/` | Optional local `.deb`s (not committed; used when `install_debs: true`) |
| `files/LMTO.md` | LMTO source + Intel apt notes |
| `files/LATEX.md` | LaTeX apt packages + phases (dep24 mapping) |
| `roles/lmto/` | LMTO install role (prereqs → Intel apt → env → build) |
| `roles/latex/` | LaTeX install role (apt → texmf → smoke) |
| `roles/latex_editors/` | LaTeX Workshop for Cursor / VS Code |

## LaTeX

Self-contained (`install_latex: true`). Does **not** require common, lab, or LMTO. See [`files/LATEX.md`](files/LATEX.md).

```bash
./scripts/bootstrap/bootstrap-latex.sh         # apt + ~/texmf + pdflatex smoke
./scripts/bootstrap/bootstrap-latex.sh apt
./scripts/verify/verify-latex.sh
```

Packages match the dep24 gather list, plus `latexmk` and `biber`.

### LaTeX editors (LaTeX Workshop)

Separate self-contained section (`install_latex_editors: true`). Installs **James-Yu.latex-workshop** into VS Code (`code`) and Cursor (`cursor`) when those CLIs exist. Skips an editor if it is not installed (does not fail). Does not require the TeX Live `latex` section.

```bash
./scripts/bootstrap/bootstrap-latex-editors.sh
./scripts/verify/verify-latex-editors.sh
```

See [`files/LATEX.md`](files/LATEX.md).

## LMTO

Separate phased step (`install_lmto: true`). See [`files/LMTO.md`](files/LMTO.md).

Defaults match the AIR workstation: **`LSYSTEM=ifx`**, archives → configure/make → Xscr.

```bash
./scripts/bootstrap/bootstrap-lmto.sh intel    # 1) Intel repo + ifx/MKL + bashrc
./scripts/bootstrap/bootstrap-lmto.sh unpack   # 2) ~/src + lmto5.04.6(.p).tar.gz
./scripts/bootstrap/bootstrap-lmto.sh rdir     # 2b) ~/R (cases for lmt)
./scripts/bootstrap/bootstrap-lmto.sh build    # 3) configure + make
./scripts/bootstrap/bootstrap-lmto.sh xscr     # 4) SCRIPT/{Xscr,grf2eps,grfonts} → ~/bin
./scripts/bootstrap/bootstrap-lmto.sh test     # 5) wipe ~/R/Fe + lmt
# or all:
./scripts/bootstrap/bootstrap-lmto.sh
./scripts/verify/verify-lmto.sh
```

Place `lmto5.04.6.tar.gz` and `lmto5.04.6p.tar.gz` in `files/`, `~/Downloads/`, or `~/src/` before unpack.

### Scratch directory (`/scratch`)

Not a separate phase — an **optional step inside `lmto-build`**. Off by default (matches AIR, where `/scratch` often does not exist).

| Setting | Default | Meaning |
|---------|---------|---------|
| `lmto_scratch_enable` | `false` | Create the scratch dir during build |
| `lmto_scratch_dir` | `/scratch` | Directory path |
| `lmto_scratch_mode` | `"0777"` | Permissions (world-writable like institute hosts) |

**What it is for:** runtime temp files for `lmt`, not compiling. When `/scratch` exists, the `lmt` wrapper uses `/scratch/$USER/…` derived from the case path under `~/R/` (e.g. Fe → `/scratch/dmazur/Fe_…`). If `/scratch` is missing, `lmt` prints a warning and continues without it.

**Enable** (e.g. to match dep24-style hosts) in `group_vars/all.yml`:

```yaml
lmto_scratch_enable: true
```

Then run (or re-run) the build phase:

```bash
./scripts/bootstrap/bootstrap-lmto.sh build
# or:
./scripts/bootstrap/bootstrap-lmto.sh
```

Verify expects `/scratch` only when `lmto_scratch_enable` is `true`.

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
