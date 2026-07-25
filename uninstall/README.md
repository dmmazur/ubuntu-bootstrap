# Uninstall / revert scripts

Bash scripts that undo what each playbook **section** installed. They read package
lists and paths from `group_vars/all.yml` (same parsers as verify).

## Safety

- Idempotent: missing packages/files are skipped.
- Destructive home deletes (`~/src`, `~/R`, `~/texmf`, …) ask for confirmation.
- Set `UNINSTALL_YES=1` to auto-answer yes (use with care).
- Shared apt packages may be listed in more than one section; uninstalling
  `common` can remove tools still wanted by other software.

## Scripts

| Script | Reverts |
|--------|---------|
| `./uninstall/uninstall-common.sh` | `apt_packages_common` |
| `./uninstall/uninstall-lab.sh` | `apt_packages_lab` |
| `./uninstall/uninstall-snaps.sh` | snaps (`code`, `telegram-desktop`, …) |
| `./uninstall/uninstall-flatpak.sh` | Flatpak apps (keeps Flathub remote) |
| `./uninstall/uninstall-debs.sh` | Cursor / VeraCrypt packages |
| `./uninstall/uninstall-claude.sh` | Claude Desktop + apt repo/keyring |
| `./uninstall/uninstall-chrome.sh` | Google Chrome + apt repo/keyring |
| `./uninstall/uninstall-dotnet.sh` | `dotnet-sdk-8.0` (+ `ppa:dotnet/backports` on Ubuntu 26.04+) |
| `./uninstall/uninstall-ollama.sh` | Ollama binary, unit, optional user |
| `./uninstall/uninstall-latex.sh` | TeX Live apt packages; optional `~/texmf` / smoke |
| `./uninstall/uninstall-latex-editors.sh` | LaTeX Workshop via `code` / `cursor` CLI |
| `./uninstall/uninstall-lmto.sh` | LMTO (see phases below) |
| `./uninstall/uninstall-all.sh` | Runs the above in reverse bootstrap order |

## LMTO phases

```bash
./uninstall/uninstall-lmto.sh              # default: xscr binaries + intel repo/packages/shell
./uninstall/uninstall-lmto.sh intel
./uninstall/uninstall-lmto.sh xscr
./uninstall/uninstall-lmto.sh build-outputs
./uninstall/uninstall-lmto.sh src          # delete ~/src (confirm)
./uninstall/uninstall-lmto.sh rdir         # delete ~/R (confirm)
./uninstall/uninstall-lmto.sh apt-deps
./uninstall/uninstall-lmto.sh nfs-links
./uninstall/uninstall-lmto.sh all
```

Default **does not** delete `~/src` or built `~/bin/ifx` trees; use `all` or the
specific phase for that.

## Examples

```bash
# Remove Chrome only
./uninstall/uninstall-chrome.sh

# Unblock apt after a broken Intel repo (also covered by lmto intel uninstall)
./uninstall/uninstall-lmto.sh intel

# Full teardown (many prompts)
./uninstall/uninstall-all.sh

# Non-interactive (dangerous)
UNINSTALL_YES=1 ./uninstall/uninstall-chrome.sh
```

After removing vendor apt lists (Claude / Chrome / Intel), scripts run
`apt-get update` so the rest of the system stays usable.
