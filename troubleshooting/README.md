# Troubleshooting

Notes from real bootstrap failures (native Ubuntu and WSL2). Each file describes
symptoms, cause, fix, and next checks.

Bootstrap scripts (`scripts/bootstrap/lib.sh`) now apply several of these fixes
automatically: ForceIPv4 for apt, remove a poisoned Intel `oneAPI.list`, repair
half-configured `openssh-server` on WSL, skip snaps on WSL by default, and skip
adding the Intel apt repo when DNS looks sinkholed. Re-read the notes below if
a run still fails or you need to force old behavior (`install_snaps_on_wsl: true`,
`lmto_intel_skip_if_unreachable: false`).

| Doc | Typical symptom |
|-----|-----------------|
| [wsl-dns-vendor-repos.md](wsl-dns-vendor-repos.md) | `apt.repos.intel.com` → `10.0.0.1`, curl timeouts; Windows browser still works |
| [intel-apt-repo-poisons-update.md](intel-apt-repo-poisons-update.md) | Every bootstrap dies at first `apt-get update` with `NO_PUBKEY` / “not signed” |
| [wsl-snap-install-fails.md](wsl-snap-install-fails.md) | `Install snap package` fails for `code` / `telegram-desktop` / `claude-code` |
| [lmto-ifx-path-shadowing.md](lmto-ifx-path-shadowing.md) | `make[4]: ifx: Permission denied` (Error 127) during LMTO build |
| [setvars-already-run-warning.md](setvars-already-run-warning.md) | Login shell prints `setvars.sh has already been run` |
| [wsl-clock-skew-apt.md](wsl-clock-skew-apt.md) | `Release file … is not valid yet (invalid for another …)` |
| [wsl-vscode-linux-vs-windows.md](wsl-vscode-linux-vs-windows.md) | Linux `code` snap vs Windows VS Code; LaTeX Workshop install fails |
| [tagged-include-skips-apt.md](tagged-include-skips-apt.md) | `bootstrap-scientific.sh` rc=0 but no `dotnet` / no `apt-*.log` for tagged apt |
| [shell-env-needs-relogin.md](shell-env-needs-relogin.md) | `ifx` / `lmt` / `code` missing until exit and reopen Ubuntu |

Logs for a failed run: `/tmp/ubuntu-bootstrap-latest/` (or the path printed at the start of the bootstrap script).
