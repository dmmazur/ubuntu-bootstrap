# Tagged bootstrap skips apt install (no error)

## Symptoms

- `./bootstrap-scientific.sh` (or any `--tags …` run) finishes with `rc=0`.
- Section banners run (e.g. `>>> DOTNET`), and on Ubuntu 26.04 the backports PPA is added.
- No `apt-dotnet-sdk-8.0.log` (and often no `apt-common.log` / `apt-lab.log`).
- `dotnet` / packages from those sections are missing.

Seen in `Downloads/U22_and_u26` (`ubuntu-bootstrap.SGzwYp` = 26.04, `UhdLoA` = 22.04).

## Cause

Ansible `include_tasks` of `tasks/logged_apt_install.yml` was tagged on the
**include** only. With `--tags`, Ansible includes the file then **skips** the
untagged shell task inside. Playbook looks successful; apt never runs.

Roles that used `apply: tags` (LaTeX, LMTO phases) were fine; playbook-level
common / lab / dotnet / claude / chrome / experimental were not.

## Fix

Use `apply: tags` on those includes (fixed in the playbook). Re-run:

```bash
./bootstrap-scientific.sh
# or only:
./scripts/bootstrap/bootstrap-dotnet.sh
```
