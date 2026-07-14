# LMTO setup inputs

## 1. Source tree → `~/src`

Provide the LMTO package by **copy, rsync, or symlink** from the other machine
(working path was `/home/dmazur/src`). The playbook expects:

```text
~/src/configure
~/src/MAK/          # includes ifx_mkl.mak
~/src/LMTO/
~/src/Readme.1st
…
```

Examples:

```bash
# rsync over ssh
rsync -aH --info=progress2 dmazur@other-host:~/src/ ~/src/

# or NFS symlink if the share is mounted
ln -s /dep24/dmazur/src ~/src   # only if that path exists on NFS
```

## 2. Intel oneAPI installers → `ubuntu-bootstrap/files/`

Place under `files/` (versioned names OK — globs match):

- `*fortran*offline.sh` — e.g. `intel-fortran-compiler-2025.1.0.601_offline.sh`
- `*onemkl*offline.sh` — e.g. `intel-onemkl-2025.1.0.803_offline.sh`

Downloads:

- https://www.intel.com/content/www/us/en/developer/tools/oneapi/fortran-compiler-download.html
- https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-download.html

Large installers under `files/` are not committed (see `.gitignore`).

## 3. Run

```bash
# After ~/src and files/*offline.sh are in place:
ansible-playbook playbook.yml --ask-become-pass --tags lmto
```

Optional NFS (`lmto_nfs_enable: true` in `group_vars/all.yml`) mounts `pam254:/dep24`.
