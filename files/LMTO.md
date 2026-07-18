# LMTO setup (AIR layout: `LSYSTEM=ifx`)

Phased install — each step can run alone:

| Phase | Script / tag | What it does |
|-------|--------------|--------------|
| 1 Intel | `./scripts/bootstrap/bootstrap-lmto.sh intel` (`lmto-intel`) | Intel apt repo, `ifx`, MKL; `~/.bashrc` (`LSYSTEM` + `setvars`); `/etc/profile.d/lmto.sh` (PATH only, no `setvars`) |
| 2 Unpack | `./scripts/bootstrap/bootstrap-lmto.sh unpack` (`lmto-unpack`) | Create `~/src`, unpack base then patch archives |
| 2b R dir | `./scripts/bootstrap/bootstrap-lmto.sh rdir` (`lmto-rdir`) | Create `~/R` for LMTO cases (`lmt` scratch paths) |
| 3 Build | `./scripts/bootstrap/bootstrap-lmto.sh build` (`lmto-build`) | apt deps, optional `/scratch`, `./configure`, edit `localoptions`, `make` |
| 4 Xscr | `./scripts/bootstrap/bootstrap-lmto.sh xscr` (`lmto-xscr`) | Copy `SCRIPT/Xscr` → `~/bin/Xscr` + symlink in `~/bin/ifx/` |
| 5 Test | `./scripts/bootstrap/bootstrap-lmto.sh test` (`lmto-test`) | Wipe `~/R/Fe`, run bare `lmt` with BCC Fe answers → `lmt.lmt` |
| Ownership | `./scripts/bootstrap/bootstrap-lmto.sh ownership` (`lmto-ownership`) | `chown` `~/src` `~/bin` `~/lib` to the login user (also runs after unpack/build even on failure) |
| All | `./scripts/bootstrap/bootstrap-lmto.sh` (`lmto`) | All enabled phases |

## Command logs

Bootstrap scripts tee console output and heavy commands into a temp directory:

```text
/tmp/ubuntu-bootstrap.XXXXXX/   # also /tmp/ubuntu-bootstrap-latest
  playbook.log                  # full ansible-playbook console
  ansible.log                   # Ansible detail (ANSIBLE_LOG_PATH)
  apt-*.log                     # apt-get update/install streams
  configure.log / make.log      # LMTO build
  lmt-Fe.log                    # Fe smoke test
```

Override with `BOOTSTRAP_LOG_DIR=/path/to/dir ./scripts/bootstrap/bootstrap-lmto.sh`.

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
| `lmto_scratch_enable` | `false` — optional `/scratch` mkdir inside build (see below) |
| Output | `~/bin/ifx`, `~/lib/ifx` |

## Scratch directory (`/scratch`)

Optional step **inside** phase 3 (`lmto-build`), not a separate tag. Default **off** (AIR often had no `/scratch`).

When `lmto_scratch_enable: true`, the build phase creates `lmto_scratch_dir` (default `/scratch`) with mode `lmto_scratch_mode` (`0777`). The `lmt` wrapper then stores large temp files under `/scratch/$USER/…` using the case path after `R/`. Without `/scratch`, `lmt` warns and runs without scratch.

```yaml
# group_vars/all.yml
lmto_scratch_enable: true
# lmto_scratch_dir: /scratch
# lmto_scratch_mode: "0777"
```

```bash
./scripts/bootstrap/bootstrap-lmto.sh build
```

## NFS

`lmto_nfs_enable` defaults to **false**. When true, mounts `pam254:/dep24` and creates home links if targets exist.

## Verify

```bash
./scripts/verify/verify-lmto.sh
```

Checks each phase (intel / unpack / rdir / build / xscr / test) against `group_vars`.

### Fe smoke test (phase 5)

Wipes `~/R/Fe`, then runs bare `lmt` (no filename arg — the wrapper only uses `Fe.lmt` if it already exists) and feeds the interactive structure prompts (order from `startlmt.f` `inif`):

| Prompt | Value |
|--------|-------|
| Space group | `229` |
| Compound | `Fe` |
| Lattice constant | `-2.86` (Å) |
| Number of sorts | `1` |
| taux tauy tauz | `0 0 0` |
| Element | `Fe` |
| Empty spheres | `y` |
| ES grid / Smt min max | blank (defaults) |

Success artifact: `~/R/Fe/lmt.lmt`. Skip with `lmto_run_fe_test: false`.

### Gather setup from another machine

```bash
./scripts/gather/gather-lmto-setup.sh
./scripts/gather/gather-lmto-setup.sh --archive
```
