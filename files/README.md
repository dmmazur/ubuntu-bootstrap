# Optional local installers

Used only when `install_debs: true` in `group_vars/all.yml` (currently **false** —
Cursor/VeraCrypt `.deb` install from this directory is skipped).

When enabled, copy downloaded `.deb` files here. Versioned names are fine — no rename needed:

- `veracrypt*.deb` (e.g. `veracrypt-1.26.29-Ubuntu-26.04-amd64.deb`)
- `cursor*.deb` (e.g. `cursor_3.9.16_amd64.deb`)

If several files match a pattern, the newest (by modification time) is installed.

`*.deb` files are gitignored so large binaries are not committed.

```bash
# After enabling install_debs: true
./scripts/bootstrap-debs.sh
./scripts/verify-debs.sh
```

For Intel oneAPI (Fortran + MKL via apt) and how to supply `~/src`, see [`LMTO.md`](LMTO.md).

## Download links

### VeraCrypt (GUI `.deb`)

- Downloads page: https://veracrypt.io/en/Downloads.html  
- GitHub release (1.26.29): https://github.com/veracrypt/VeraCrypt/releases/tag/VeraCrypt_1.26.29  

Pick the package that matches your Ubuntu version (amd64 examples):

| Ubuntu | Direct `.deb` |
|--------|----------------|
| 26.04 | https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_1.26.29/veracrypt-1.26.29-Ubuntu-26.04-amd64.deb |
| 24.04 | https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_1.26.29/veracrypt-1.26.29-Ubuntu-24.04-amd64.deb |
| 22.04 | https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_1.26.29/veracrypt-1.26.29-Ubuntu-22.04-amd64.deb |

Example:

```bash
cd files
curl -fLO https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_1.26.29/veracrypt-1.26.29-Ubuntu-26.04-amd64.deb
```

### Cursor (Linux `.deb`)

- Downloads page (choose **DEB** for Linux): https://cursor.com/download  
- Mirror/path also listed as: https://cursor.com/en/downloads  

Cursor’s site always serves the latest `.deb`; there is no fixed version URL to pin long-term. After you install once, Cursor usually adds its apt repo so later updates can use `apt`.

Example (download via browser into `files/`, or):

```bash
# After saving the .deb from the site into ~/Downloads:
cp ~/Downloads/cursor_*.deb files/
```

**Alternative (no `.deb` in `files/`):** official apt repo after key install — see  
https://downloads.cursor.com/aptrepo and key https://downloads.cursor.com/keys/anysphere.asc  
(not wired into the playbook yet; when debs are enabled, `.deb` + `--tags debs` / `./scripts/bootstrap-debs.sh` is the path).
