# WSL: VS Code Linux snap vs Windows VS Code

## Symptoms

- Bootstrap installs the Linux `code` snap (`snaps` section).
- `code` in a WSL terminal opens **Windows** VS Code (Remote-WSL) — or the WSL stub asks you to uninstall the Linux version.
- LaTeX Workshop install via `code --install-extension` fails / prompts `[y/N]` (`latex-workshop-code.log`).

## Cause

On WSL:

1. Playbook may install the **Linux** VS Code snap.
2. Windows VS Code injects a **`code` shim** into WSL for Remote-WSL.
3. Microsoft’s recommended setup is **Windows VS Code + Remote-WSL**, not a second Linux GUI VS Code.

So “site works in the browser” / “code opens Windows” does not mean the snap path is what you want for extensions.

## Fix / advice

- Prefer **Windows** VS Code with the WSL remote; install LaTeX Workshop in that Windows VS Code (it applies to the remote).
- Optional: remove the Linux snap to avoid confusion:

```bash
sudo snap remove code
```

- To force the Linux binary (needs WSLg; not recommended): `snap run code` or `/snap/bin/code`.

## Next steps

```bash
which -a code
type -a code
snap list code 2>/dev/null
```

For snap install failures, see [wsl-snap-install-fails.md](wsl-snap-install-fails.md).
