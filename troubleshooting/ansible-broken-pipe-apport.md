# Ubuntu “ansible-playbook crashed” (BrokenPipeError)

## Symptoms

Apport dialog:

```text
Sorry, the application ansible-playbook has stopped unexpectedly.
ansible-playbook crashed with BrokenPipeError in locking_wrapper():
[Errno 32] Broken pipe
```

Often after `./bootstrap-*.sh` or `--tags lmto` on **Ubuntu 26.04** (Python 3.14).

## Cause

Bootstrap used to run:

```bash
ansible-playbook … 2>&1 | tee playbook.log
```

When that pipe closes (Ctrl+C, closed terminal, or cleanup), Ansible’s Python
process can raise an unhandled `BrokenPipeError` while flushing/locking output.
Ubuntu then shows a crash report. It does **not** mean the packages failed for
that reason.

## What to do

1. Dismiss / close the Apport dialog (“Close”).
2. Check the real result in `/tmp/ubuntu-bootstrap-latest/` (`ansible.log`,
   per-command `*.log`) or re-run the section.
3. Current bootstrap runs `ansible-playbook` **without** `| tee` so this dialog
   should stop appearing.

## If it still appears

You likely interrupted the run. Safe to ignore for BrokenPipeError. To stop
Apport prompts generally: System Settings → Privacy → Diagnostics, or
`sudo systemctl stop apport.service` (optional).
