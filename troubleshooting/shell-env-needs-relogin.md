# Commands missing until logout / new WSL session

## Symptoms

- Bootstrap finished successfully.
- In the **same** terminal, `ifx`, `lmt`, `code`, etc. are “not found”.
- After `exit` and opening Ubuntu again, they work.

## Cause

Installers update `~/.bashrc`, `/etc/profile.d/lmto.sh`, and snap PATH for
**new** shells. A `./bootstrap*.sh` process cannot change the parent shell’s
environment.

## Fix (no logout)

```bash
source /path/to/ubuntu-bootstrap/scripts/bootstrap/activate-env.sh
```

Or replace the current shell with a login shell:

```bash
exec bash -l
```

Bootstrap scripts print the `source …/activate-env.sh` hint when they finish
successfully.
