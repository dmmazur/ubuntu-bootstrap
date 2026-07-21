# WSL: apt “Release file is not valid yet” (clock skew)

## Symptoms

Near the start of bootstrap (`Installing Ansible and helper packages`):

```text
E: Release file for http://security.ubuntu.com/ubuntu/dists/…/InRelease is not valid yet
   (invalid for another 1h 46min …)
```

Same for other Ubuntu (and sometimes Chrome) repos. Seen in `Downloads/WSL_AT_JUNGLE/error.log` when re-running `bootstrap-lmto.sh`.

## Cause

WSL system clock is **behind** real time (often after Windows sleep/hibernate or Windows↔WSL time sync issues). Apt treats Release files as “from the future” and refuses them.

This is unrelated to LMTO itself; any `apt-get update` can show it.

## Fix

```bash
date                          # does it look wrong?
sudo hwclock -s               # sync from hardware / Windows (often enough)
# or, if available:
# sudo ntpdate pool.ntp.org
date
sudo apt-get update
```

Also check Windows time zone and that WSL is not stuck on a bad UTC offset.

## Next steps

```bash
timedatectl status
cat /etc/timezone
# Compare to Windows clock; then retry bootstrap
./scripts/bootstrap/bootstrap-lmto.sh
```
