# LMTO setup (AIR layout: `LSYSTEM=ifx`)

Phased install — each step can run alone:

| Phase | Script / tag | What it does |
|-------|--------------|--------------|
| 1 Intel | `./scripts/bootstrap-lmto.sh intel` (`lmto-intel`) | Intel apt repo, `ifx`, MKL, `~/.bashrc` (`LSYSTEM` + `setvars`), `/etc/profile.d/lmto.sh` |
| 2 Unpack | `./scripts/bootstrap-lmto.sh unpack` (`lmto-unpack`) | Create `~/src`, unpack base then patch archives |
| 3 Build | `./scripts/bootstrap-lmto.sh build` (`lmto-build`) | apt deps, `./configure`, edit `localoptions`, `make` |
| 4 Xscr | `./scripts/bootstrap-lmto.sh xscr` (`lmto-xscr`) | Copy `SCRIPT/Xscr` → `~/bin/Xscr` + symlink in `~/bin/ifx/` |
| Ownership | `./scripts/bootstrap-lmto.sh ownership` (`lmto-ownership`) | `chown` `~/src` `~/bin` `~/lib` to the login user (also runs after unpack/build even on failure) |
| All | `./scripts/bootstrap-lmto.sh` (`lmto`) | All enabled phases |

## Archives (phase 2)

Place both tarballs in `files/`, `~/Downloads/`, or `~/src/`:

```text
lmto5.04.6.tar.gz     # base
lmto5.04.6p.tar.gz    # patch (includes MAK/ifx_mkl.mak)
```

Unpack order matches `Readme.1st`: base first, patch second.

## Intel oneAPI (phase 1)

| Package | Purpose |
|---------|---------|
| `intel-oneapi-compiler-fortran` | `ifx` |
| `intel-oneapi-mkl` | MKL (`-qmkl` via setvars) — matches AIR |

`~/.bashrc` gets (AIR last two lines):

```bash
export LSYSTEM=ifx
source /opt/intel/oneapi/setvars.sh
```

## Build defaults (`group_vars/all.yml`)

| Setting | Value |
|---------|-------|
| `lmto_lsystem` | `ifx` |
| `lmto_makefile_intel` | `ifx_mkl.mak` |
| `lmto_fflags_extra` | `-xHost -debug all -g -traceback` |
| `lmto_make_jobs` | `1` (LMTO makefiles are not parallel-safe) |
| `lmto_exclude_targets` | `GRFTOOLS`, `XSCR` (AIR omitted these; old C vs modern gcc) |
| Output | `~/bin/ifx`, `~/lib/ifx` |

## NFS

`lmto_nfs_enable` defaults to **false**. When true, mounts `pam254:/dep24` and creates home links if targets exist.

## Verify

```bash
./scripts/verify-lmto.sh
```

Checks each phase (intel / unpack / build / xscr) against `group_vars`.

### Gather setup from another machine

```bash
./scripts/gather-lmto-setup.sh
./scripts/gather-lmto-setup.sh --archive
```
