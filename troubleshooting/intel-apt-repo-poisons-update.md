# Intel apt repo poisons every `apt-get update`

## Symptoms

- Sections that **already worked** (common, lab, latex, chrome, …) suddenly fail at the **first** step of any `./scripts/bootstrap/*.sh`.
- Log is only `apt-prereqs-update.log` with:

```text
W: OpenPGP signature verification failed: https://apt.repos.intel.com/oneapi ...
   NO_PUBKEY BAC6F0C353D04109
E: The repository 'https://apt.repos.intel.com/oneapi all InRelease' is not signed.
```

Seen after a failed LMTO intel run on WSL (`Downloads/WSL_AT_AIM`: `F0XI3p`, `vsWj7a`, `pIGbiQ`).

## Cause

Not “Ansible stopped mid-playbook only.” The intel phase left a **system-wide** apt config:

1. `/etc/apt/sources.list.d/oneAPI.list` was added.
2. The Intel GPG keyring was missing or incomplete (curl to Intel failed earlier).
3. Later, apt can fetch Intel `InRelease` but cannot verify it → hard `E:` on **every** `apt-get update`.

Every bootstrap script calls `ensure_prerequisites` → `apt-get update` first, so **all** sections fail until the bad repo is removed or the key is fixed.

## Fix

Unblock apt immediately:

```bash
sudo rm -f /etc/apt/sources.list.d/oneAPI.list
sudo rm -f /usr/share/keyrings/oneapi-archive-keyring.gpg
sudo apt-get update
```

Then re-run the section you need (e.g. `./scripts/bootstrap/bootstrap-chrome.sh`).

Only re-run LMTO intel **after** Intel HTTPS works (see [wsl-dns-vendor-repos.md](wsl-dns-vendor-repos.md)):

```bash
./scripts/bootstrap/bootstrap-lmto.sh intel
```

## Next steps to troubleshoot

```bash
ls -la /etc/apt/sources.list.d/oneAPI.list \
      /usr/share/keyrings/oneapi-archive-keyring.gpg
apt-cache policy intel-oneapi-compiler-fortran
sudo apt-get update -o Debug::Acquire::https=true 2>&1 | tail -40
```

If the list must stay but the key is wrong, re-fetch the key from a working network:

```bash
curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
  | sudo gpg --dearmor -o /usr/share/keyrings/oneapi-archive-keyring.gpg
sudo apt-get update
```
