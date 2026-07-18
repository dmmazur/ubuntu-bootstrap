# LaTeX / TeX Live (dep24-style apt install)

Self-contained section — run alone without common, lab, or LMTO:

```bash
./scripts/bootstrap/bootstrap-latex.sh
./scripts/verify/verify-latex.sh
```

## Phases

| Phase | Script / tag | What it does |
|-------|--------------|--------------|
| 1 Apt | `./scripts/bootstrap/bootstrap-latex.sh apt` (`latex-apt`) | Own `apt-get update` + curated TeX Live packages |
| 2 texmf | `./scripts/bootstrap/bootstrap-latex.sh texmf` (`latex-texmf`) | Create `~/texmf/…`; unpack `files/latex-userdata.tgz` if present |
| 3 Smoke | `./scripts/bootstrap/bootstrap-latex.sh smoke` (`latex-smoke`) | `pdflatex` tiny `~/TeX/smoke/smoke.tex` → `smoke.pdf` |
| All | `./scripts/bootstrap/bootstrap-latex.sh` (`latex`) | All enabled phases |

## Packages (`apt_packages_latex`)

Matches dep24 `apt-mark showmanual` TeX list, plus `latexmk` and `biber` (missing on dep24 but useful):

```text
texlive-latex-base
texlive-latex-recommended
texlive-latex-extra
texlive-fonts-extra
texlive-font-utils
texlive-extra-utils
texlive-bibtex-extra
texlive-publishers
texlive-science
texlive-lang-cyrillic
texinfo
latexmk
biber
```

Not installed: `texlive-full`, upstream `/usr/local/texlive`, or `texlive-xetex` (dep24 had no `xelatex`).

## User data

Optional: place `files/latex-userdata.tgz` (from `./scripts/gather/gather-latex-setup.sh --archive` on another machine). Unpacked into `$HOME` during the texmf phase.

## Toggle

```yaml
# group_vars/all.yml
install_latex: true          # whole section
latex_install_apt: true
latex_ensure_texmf: true
latex_run_smoke: true
```

## Planned follow-up (not in this section)

**Editor extensions** — separate playbook section for Cursor / VS Code **LaTeX Workshop** (and similar). Implement after this LaTeX install section is stable.

## Verify

```bash
./scripts/verify/verify-latex.sh
pdflatex --version
kpsewhich article.cls
ls ~/TeX/smoke/smoke.pdf
```
