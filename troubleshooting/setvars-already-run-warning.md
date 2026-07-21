# Warning: `setvars.sh has already been run`

## Symptoms

At Ubuntu/WSL login (especially **login** shells):

```text
:: WARNING: setvars.sh has already been run. Skipping re-execution.
   To force a re-execution of setvars.sh, use the '--force' option.
…
```

Desktop terminals (interactive **non-login**) often never show it.

## Cause

Intel `setvars.sh` was sourced twice in one startup. Typical bootstrap layout:

1. `/etc/profile.d/lmto.sh` (login) — must **not** source setvars (PATH/`LSYSTEM` only)
2. `~/.bashrc` — `source /opt/intel/oneapi/setvars.sh` (AIR-style)

WSL often starts a login shell → both run → second call prints the warning. GNOME Terminal is usually non-login → only `.bashrc` → no warning, even if both files used to source setvars.

## Fix

Playbook template `roles/lmto/templates/lmto.sh.j2` should only set `LSYSTEM` + `~/bin` PATH. Redeploy:

```bash
./scripts/bootstrap/bootstrap-lmto.sh intel
```

Or edit `/etc/profile.d/lmto.sh` by hand and remove the `setvars` block; keep the `PATH` / `LSYSTEM` lines.

Confirm `.bashrc` still has (AIR):

```bash
export LSYSTEM=ifx
source /opt/intel/oneapi/setvars.sh
```

## Next steps

```bash
grep -n setvars /etc/profile.d/lmto.sh ~/.bashrc ~/.profile 2>/dev/null
# Login test:
bash -l -c 'command -v ifx' 2>&1 | head -20
```

The warning is noisy but usually harmless if the first `setvars` already configured the environment.
