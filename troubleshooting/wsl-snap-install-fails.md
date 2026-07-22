# WSL: snap install fails

## Symptoms

- Playbook task `Install snap package` fails for `code`, `telegram-desktop`, and/or `claude-code`.
- Ansible message is vague, e.g. `Ooops! Snap installation failed while executing '['state', 'classic', …]'`.
- Common + lab apt packages may have succeeded just before snaps.

Seen in `Downloads/WSL_AT_AIM/ubuntu-bootstrap.LLt5hG`.

## Cause

On WSL2, snapd is fragile (systemd, confinement, store connectivity). Failures are often:

- Cannot reach the Snap Store (same class of network/DNS issues as vendor apt — see [wsl-dns-vendor-repos.md](wsl-dns-vendor-repos.md))
- snapd not fully working under WSL
- Long timeouts that surface only as Ansible’s generic error

Linux VS Code via snap is also a poor fit on WSL; prefer Windows VS Code + Remote-WSL ([wsl-vscode-linux-vs-windows.md](wsl-vscode-linux-vs-windows.md)).

## Automatic mitigation

On WSL, the playbook **skips snaps by default** (`install_snaps_on_wsl: false`). Set `install_snaps_on_wsl: true` in `group_vars/all.yml` to force them. If snaps are enabled, individual snap failures are **non-fatal** (`ignore_errors`) so other sections can continue.

## Fix / workarounds

1. Confirm snapd:

```bash
systemctl is-active snapd
snap version
snap find hello   # store reachability
```

2. Retry one snap manually for a clearer error:

```bash
sudo snap install code --classic
```

3. If store/DNS is the issue, fix WSL DNS first, then:

```bash
./scripts/bootstrap/bootstrap-snaps.sh
```

4. If snaps are not needed on this host, leave the WSL default (already skips snaps), or set:

```yaml
install_snaps: false
# or on WSL keep install_snaps: true but:
install_snaps_on_wsl: false
```

Or skip the tag and install GUI apps on Windows instead.

## Next steps

- Check `journalctl -u snapd -n 80 --no-pager`
- `snap changes` / `snap tasks --last=install`
- Decide per machine: WSL often does not need Linux VS Code / Telegram snaps
