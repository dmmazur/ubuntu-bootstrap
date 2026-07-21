# LMTO: `ifx: Permission denied` during make

## Symptoms

- Configure succeeds; `make` fails almost immediately:

```text
ifx -c … wkinit.f
make[4]: ifx: Permission denied
make[4]: *** […/wmem.mod] Error 127
```

- Detect task may still report `ifx rc=0` and choose `ifx_mkl.mak`.

Seen in `Downloads/WSL_AT_JUNGLE` make/playbook logs.

## Cause

Two different things share the name `ifx`:

| Thing | Path |
|--------|------|
| Intel Fortran compiler | `/opt/intel/oneapi/compiler/…/bin/ifx` |
| LMTO `LSYSTEM` output dir | `~/bin/ifx/` (directory) |

If `PATH` puts `~/bin` **before** Intel’s bin, the shell/`make` resolves `ifx` to the **directory**. Executing a directory → `Permission denied` (Error 127).

This happened when bootstrap sourced `setvars`, then prepended `~/bin` again (undoing AIR’s order). Interactive AIR shells usually run `setvars` **after** `~/bin` is on `PATH`, so Intel stays first.

Bash `command -v` may skip directories and still show the real compiler; **GNU make does not** — so detect can look fine while make fails.

## Fix

Current playbook order (build/test + profile.d PATH helper): put `~/bin` on `PATH`, **then** source `setvars` so Intel is prepended.

On an already-broken shell, temporarily:

```bash
. /opt/intel/oneapi/setvars.sh
export PATH="$(dirname "$(command -v ifx)"):$HOME/bin/ifx:$HOME/bin:$PATH"
# ensure command -v ifx is under /opt/intel/...
cd ~/src && make
```

Or re-run with the fixed playbook:

```bash
./scripts/bootstrap/bootstrap-lmto.sh build
```

## Next steps

```bash
command -v ifx
type -a ifx
ls -ld "$(command -v ifx)"   # must be a file, not a directory
echo "$PATH" | tr ':' '\n' | head -20
```
