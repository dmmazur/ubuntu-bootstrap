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

## 2. Intel oneAPI (apt)

The playbook adds Intel’s apt repo and installs:

| Package | Purpose |
|---------|---------|
| `intel-oneapi-compiler-fortran` | `ifx` Fortran compiler |
| `intel-oneapi-mkl-devel` | MKL for **building** LMTO (`ifx_mkl.mak`, `-qmkl`) |

Runtime-only MKL (`intel-oneapi-mkl`) is not used — compile needs `-devel`.

Repo setup (automatic):  
https://www.intel.com/content/www/us/en/docs/oneapi/installation-guide-linux/2025-0/apt-001.html

Manual equivalent:

```bash
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
  | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
  | sudo tee /etc/apt/sources.list.d/oneAPI.list
sudo apt update
sudo apt install intel-oneapi-compiler-fortran intel-oneapi-mkl-devel
source /opt/intel/oneapi/setvars.sh
```

No offline `*offline.sh` installers in `files/` are required.

## 3. Run

```bash
# After ~/src is in place:
sudo --preserve-env=HOME \
  ansible-playbook playbook.yml --tags lmto -e ansible_become=false
```

Optional NFS (`lmto_nfs_enable: true` in `group_vars/all.yml`) mounts `pam254:/dep24`.
