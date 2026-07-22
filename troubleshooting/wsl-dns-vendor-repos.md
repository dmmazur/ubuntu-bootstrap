# WSL: vendor repos unreachable (DNS / filter)

## Symptoms

- LMTO intel phase fails downloading the Intel key or packages, e.g.:
  - `curl: (28) Failed to connect to apt.repos.intel.com port 443`
  - `Could not connect to apt.repos.intel.com:443 (10.0.0.1), connection timed out`
  - `E: Unable to locate package intel-oneapi-compiler-fortran`
- Ubuntu mirrors (`archive.ubuntu.com`) often still work (`Hit:` in apt logs).
- Pasting the same Intel URL into a **Windows** browser works.

Seen in WSL2 logs under `Downloads/WSL_AT_AIM` (runs `MDuNMu`, `Qx9YSS`, `UeGaQ5`).

## Cause

WSL resolves `apt.repos.intel.com` to a **wrong address** (commonly `10.0.0.1` — private / sinkhole). That is not a real public Intel CDN IP.

Typical reasons:

- Corporate / filtered DNS on the Windows host, inherited by WSL via `/etc/resolv.conf`
- Windows browser uses **DNS-over-HTTPS** and gets the real IP; WSL does not

Snaps / other vendor hosts can fail the same way even when Ubuntu apt still works.

## Automatic mitigation

Bootstrap detects sinkholed `apt.repos.intel.com` and sets `bootstrap_intel_dns_bad`. With `lmto_intel_skip_if_unreachable: true` (default), the LMTO intel phase **does not** add `oneAPI.list`, so a failed Intel fetch cannot poison apt. Fix DNS, then re-run `./scripts/bootstrap/bootstrap-lmto.sh intel`.

## Fix

1. Confirm bad DNS inside WSL:

```bash
getent hosts apt.repos.intel.com
# Bad: 10.0.0.1 (or other RFC1918)
curl -I --max-time 15 https://apt.repos.intel.com/
```

2. Prefer fixing WSL networking from Windows. In `%UserProfile%\.wslconfig`:

```ini
[wsl2]
dnsTunneling=true
# or try:
# networkingMode=mirrored
```

Then from PowerShell: `wsl --shutdown`, reopen Ubuntu, retest `getent hosts`.

3. Or override DNS inside WSL (temporary):

```bash
# /etc/wsl.conf
[network]
generateResolvConf = false
```

```bash
sudo rm -f /etc/resolv.conf
echo -e 'nameserver 1.1.1.1\nnameserver 8.8.8.8' | sudo tee /etc/resolv.conf
```

`wsl --shutdown` again, then retest.

4. When `getent` shows a public IP and `curl` succeeds:

```bash
./scripts/bootstrap/bootstrap-lmto.sh intel
```

## Next steps if still blocked

- Ask IT to allowlist `apt.repos.intel.com` (and Snap Store if snaps fail).
- Check whether a corporate proxy is required in WSL (`http_proxy` / `https_proxy`).
- As a last resort, install Intel oneAPI on a machine with clean network and copy toolkits, or skip intel apt and use a prebuilt compiler tree.

Also see [intel-apt-repo-poisons-update.md](intel-apt-repo-poisons-update.md) — a half-added Intel list can break **all** later bootstrap runs.
