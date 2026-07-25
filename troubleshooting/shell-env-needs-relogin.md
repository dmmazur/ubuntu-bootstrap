# Commands missing until logout / new WSL session

## Symptoms

- Bootstrap finished (or failed late).
- In the **same** terminal, `ifx`, `lmt`, `orx`, `dotnet`, `code`, etc. are “not found”.
- After `exit` and opening Ubuntu again (or a new WSL tab), they work.

## Cause

Installers update `~/.bashrc`, `/etc/profile.d/lmto.sh`, and snap PATH for
**new** shells. A `./bootstrap*.sh` **child process cannot** change the parent
shell’s environment — that is a shell limitation, not a failed package install.

## Fix (no logout)

```bash
source /path/to/ubuntu-bootstrap/scripts/bootstrap/activate-env.sh
```

Or replace the current shell with a login shell:

```bash
exec bash -l
```

Bootstrap scripts print this hint when they finish (success **or** failure).

## Related: lmto-ui “dotnet not found” during playbook

If the log shows `No such file or directory: b'command'` while resolving
dotnet, that was an Ansible `command` module bug (fixed: use shell +
`/usr/bin/dotnet`). Re-run:

```bash
./scripts/bootstrap/bootstrap-lmto-ui.sh
```
