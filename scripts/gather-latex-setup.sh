#!/usr/bin/env bash
# Gather LaTeX / TeX Live setup from a machine that already works.
# Copy the generated report (and optional archive) to the new PC for reinstall.
#
# Usage (on the machine WITH LaTeX already installed):
#   ./scripts/gather-latex-setup.sh
#   ./scripts/gather-latex-setup.sh -o ~/Downloads/latex-setup-report.txt
#   ./scripts/gather-latex-setup.sh --archive   # also pack ~/texmf + key configs
#
# Safe: read-only probes + optional tar of user texmf (no sudo required for most checks).
# Some package queries work better with sudo; the script asks only if needed.

set -euo pipefail

OUT="${HOME}/Downloads/latex-setup-report-$(date +%Y%m%d-%H%M%S).txt"
DO_ARCHIVE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) OUT="$2"; shift 2 ;;
    --archive) DO_ARCHIVE=1; shift ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$(dirname "${OUT}")"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

section() {
  printf '\n================================================================================\n'
  printf '%s\n' "$*"
  printf '================================================================================\n'
}

run() {
  local title="$1"
  shift
  printf '\n--- %s ---\n' "${title}"
  printf '+ %s\n' "$*"
  # shellcheck disable=SC2068
  if ! "$@" 2>&1; then
    printf '(command failed or not available, exit %s)\n' "$?"
  fi
}

run_sh() {
  local title="$1"
  local cmd="$2"
  printf '\n--- %s ---\n' "${title}"
  printf '+ %s\n' "${cmd}"
  if ! bash -c "${cmd}" 2>&1; then
    printf '(command failed or not available)\n'
  fi
}

{
  section "LaTeX / TeX Live setup gather"
  printf 'Host:        %s\n' "$(hostname 2>/dev/null || echo unknown)"
  printf 'User:        %s\n' "$(whoami)"
  printf 'Home:        %s\n' "${HOME}"
  printf 'Date:        %s\n' "$(date -Is)"
  printf 'OS:          %s\n' "$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}")"
  printf 'Kernel:      %s\n' "$(uname -a)"

  section "1) TeX-related binaries (which + versions)"
  for b in \
    latex pdflatex xelatex lualatex platex uplatex \
    bibtex biber makeindex xindy \
    latexmk texhash kpsewhich fmtutil-sys tlmgr \
    dvips dvipdf mx dvipdfmx ps2pdf epstopdf \
    asymptote metapost mpost context \
    pandoc groff \
    tex texi2dvi makeinfo
  do
    if command -v "${b}" >/dev/null 2>&1; then
      p="$(command -v "${b}")"
      printf '%-16s %s\n' "${b}" "${p}"
      # version probes (best-effort)
      case "${b}" in
        pdflatex|xelatex|lualatex|latex)
          "${b}" --version 2>/dev/null | head -3 || true
          ;;
        tlmgr|latexmk|biber|pandoc|kpsewhich)
          "${b}" --version 2>/dev/null | head -5 || true
          ;;
      esac
      printf '\n'
    else
      printf '%-16s (not found)\n' "${b}"
    fi
  done

  section "2) kpsewhich / TEXMF paths"
  if command -v kpsewhich >/dev/null 2>&1; then
    run_sh "kpsewhich -var-value TEXMFHOME" 'kpsewhich -var-value TEXMFHOME'
    run_sh "kpsewhich -var-value TEXMFLOCAL" 'kpsewhich -var-value TEXMFLOCAL'
    run_sh "kpsewhich -var-value TEXMFDIST" 'kpsewhich -var-value TEXMFDIST'
    run_sh "kpsewhich -var-value TEXMFVAR" 'kpsewhich -var-value TEXMFVAR'
    run_sh "kpsewhich -var-value TEXMFCONFIG" 'kpsewhich -var-value TEXMFCONFIG'
    run_sh "kpsewhich -var-value TEXMFCNF" 'kpsewhich -var-value TEXMFCNF'
    run_sh "kpsewhich article.cls" 'kpsewhich article.cls'
    run_sh "kpsewhich -all texmf.cnf | head" 'kpsewhich -all texmf.cnf 2>/dev/null | head -20'
  else
    echo "kpsewhich not found — TeX Live may be missing or not on PATH"
  fi

  section "3) Environment variables (current shell + profile snippets)"
  env | grep -iE '^(TEX|LATEX|BIB|PATH)=' | sort || true
  printf '\n--- profile / bashrc / zshrc TeX-related lines ---\n'
  for f in \
    "${HOME}/.profile" "${HOME}/.bash_profile" "${HOME}/.bashrc" \
    "${HOME}/.zshrc" "${HOME}/.zshenv" \
    /etc/profile.d/*tex* /etc/environment
  do
    [[ -e "${f}" ]] || continue
    if grep -nEi 'tex|latex|TEXMF|tlmgr|/usr/local/texlive' "${f}" 2>/dev/null; then
      printf '# from %s\n' "${f}"
      grep -nEi 'tex|latex|TEXMF|tlmgr|/usr/local/texlive' "${f}" 2>/dev/null || true
      printf '\n'
    fi
  done

  section "4) APT: TeX / LaTeX packages (installed)"
  if command -v dpkg-query >/dev/null 2>&1; then
    run_sh "dpkg -l '*tex*' '*latex*' '*biber*' '*latexmk*' (installed)" \
      "dpkg-query -W -f='\${Status}\t\${Package}\t\${Version}\n' 2>/dev/null | awk '/^install ok installed/ && \$2 ~ /(^|-)(tex|latex|biber|latexmk|asymptote|context|xindy|feynmf|preview|lyx)/ {print}' | sort"
    run_sh "apt-mark showmanual | grep -iE 'tex|latex|biber|latexmk'" \
      "apt-mark showmanual 2>/dev/null | grep -iE 'tex|latex|biber|latexmk|asymptote|lyx' | sort"
  fi

  section "5) TeX Live from upstream tlmgr (if present)"
  if command -v tlmgr >/dev/null 2>&1; then
    run "tlmgr version" tlmgr version
    run_sh "tlmgr info schemes (installed schemes if any)" \
      'tlmgr info schemes 2>/dev/null | head -80 || tlmgr list --only-installed 2>/dev/null | head -5'
    run_sh "tlmgr list --only-installed (first 200 lines)" \
      'tlmgr list --only-installed 2>/dev/null | head -200'
    run_sh "tlmgr list --only-installed | wc -l" \
      'tlmgr list --only-installed 2>/dev/null | wc -l'
    # Full installed list to side file for reinstall
    if tlmgr list --only-installed >"${TMP}/tlmgr-installed.txt" 2>/dev/null; then
      cp "${TMP}/tlmgr-installed.txt" "${OUT%.txt}-tlmgr-installed.txt"
      printf 'Wrote full tlmgr list: %s\n' "${OUT%.txt}-tlmgr-installed.txt"
    fi
  else
    echo "tlmgr not found (typical for Ubuntu texlive apt packages; OK)"
  fi

  section "6) Install layout: apt TeX Live vs /usr/local/texlive"
  run_sh "ls /usr/local/texlive" 'ls -la /usr/local/texlive 2>/dev/null || echo "(no /usr/local/texlive)"'
  run_sh "ls /usr/share/texlive" 'ls -la /usr/share/texlive 2>/dev/null | head -30 || echo "(no /usr/share/texlive)"'
  run_sh "readlink -f \$(command -v pdflatex 2>/dev/null)" \
    'command -v pdflatex >/dev/null && readlink -f "$(command -v pdflatex)" || echo "(no pdflatex)"'

  section "7) User / local texmf trees"
  for d in \
    "${HOME}/texmf" \
    "${HOME}/.texmf" \
    "${HOME}/.texlive" \
    "${HOME}/.config/latexmk" \
    "${HOME}/.local/share/latex" \
    /usr/local/share/texmf \
    /usr/share/texmf
  do
    if [[ -e "${d}" ]]; then
      printf 'FOUND %s\n' "${d}"
      du -sh "${d}" 2>/dev/null || true
      find "${d}" -maxdepth 3 \( -type f -o -type d -o -type l \) 2>/dev/null | head -80
      printf '\n'
    else
      printf 'absent %s\n' "${d}"
    fi
  done

  section "8) Config files (paths + excerpts)"
  for f in \
    "${HOME}/.latexmkrc" \
    "${HOME}/latexmkrc" \
    "${HOME}/.chktexrc" \
    "${HOME}/.config/latexmk/latexmkrc" \
    /etc/texmf/texmf.cnf \
    /etc/texmf/web2c/texmf.cnf \
    /etc/texmf/updmap.d \
    /etc/texmf/fmt.d
  do
    if [[ -e "${f}" ]]; then
      printf 'FOUND %s\n' "${f}"
      if [[ -f "${f}" ]]; then
        ls -la "${f}"
        sed -n '1,80p' "${f}" 2>/dev/null || true
      else
        ls -la "${f}" 2>/dev/null | head -40
      fi
      printf '\n'
    fi
  done
  run_sh "find home for *latex* *texmf* *chktex* configs" \
    "find \"${HOME}\" -maxdepth 3 \( -iname '*latexmk*' -o -iname '.chktexrc' -o -iname 'texmf.cnf' -o -iname '*.latex' \) 2>/dev/null | head -50"

  section "9) Symlinks / NFS TeX trees (common on institute machines)"
  run_sh "home symlinks mentioning TeX/tex" \
    "ls -la \"${HOME}\" 2>/dev/null | grep -iE 'tex|latex' || true"
  run_sh "findmnt / grep tex" \
    "findmnt 2>/dev/null | grep -iE 'tex|latex' || true"
  run_sh "fstab tex lines" \
    "grep -iE 'tex|latex' /etc/fstab 2>/dev/null || true"

  section "10) Editors / helpers often used with LaTeX"
  for b in code cursor gedit emacs vim nvim texstudio texmaker kile lyx gummi vscode; do
    if command -v "${b}" >/dev/null 2>&1; then
      printf '%-12s %s\n' "${b}" "$(command -v "${b}")"
    fi
  done
  run_sh "VS Code / Cursor LaTeX extensions (if dirs exist)" \
    "ls \"${HOME}/.vscode/extensions\" 2>/dev/null | grep -iE 'latex|tex' || ls \"${HOME}/.cursor/extensions\" 2>/dev/null | grep -iE 'latex|tex' || echo '(none found)'"

  section "11) Recent shell history: latex/pdf commands (best-effort)"
  for hf in "${HOME}/.bash_history" "${HOME}/.zsh_history"; do
    [[ -f "${hf}" ]] || continue
    printf '# from %s\n' "${hf}"
    grep -iE 'pdflatex|xelatex|lualatex|latexmk|bibtex|biber|texlive|tlmgr|make pdf|\.tex' "${hf}" 2>/dev/null | tail -80 || true
    printf '\n'
  done

  section "12) Suggested reinstall notes (generated)"
  cat <<'EOF'
On the NEW machine, typical paths:

A) Ubuntu apt TeX Live (simpler; matches many Ubuntu installs)
   sudo apt update
   sudo apt install texlive-full
   # or a smaller set from section 4 "apt-mark showmanual" / dpkg list above
   # Common minimal desktop set:
   #   texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended
   #   texlive-xetex texlive-luatex latexmk biber

B) Upstream TeX Live via install-tl + tlmgr
   # Use the tlmgr-installed list file next to this report if present.
   # Install TeX Live, put it on PATH, then:
   #   tlmgr install $(awk ... from *-tlmgr-installed.txt)

C) Restore user files
   - Copy ~/texmf (and ~/.latexmkrc) from the archive if created.
   - Re-create any TeX NFS/symlink paths from section 9.
   - Re-apply PATH / TEXMF* lines from section 3.

D) Verify
   kpsewhich article.cls
   pdflatex --version
   # compile a tiny test .tex
EOF

  section "13) Quick package name dump (for apt reinstall)"
  if command -v dpkg-query >/dev/null 2>&1; then
    dpkg-query -W -f='${Status} ${Package}\n' 2>/dev/null \
      | awk '/^install ok installed/ && $3 ~ /^(texlive|tex-|latex|biber|latexmk|asymptote|context|xindy|lyx|preview-latex|feynmf)/ {print $3}' \
      | sort -u
  fi

} | tee "${OUT}"

ARCHIVE_OUT=""
if [[ "${DO_ARCHIVE}" -eq 1 ]]; then
  ARCHIVE_OUT="${OUT%.txt}-userdata.tgz"
  section "Creating user TeX archive" | tee -a "${OUT}"
  TO_PACK=()
  for p in \
    "${HOME}/texmf" \
    "${HOME}/.texmf" \
    "${HOME}/.latexmkrc" \
    "${HOME}/latexmkrc" \
    "${HOME}/.chktexrc" \
    "${HOME}/.config/latexmk"
  do
    [[ -e "${p}" ]] && TO_PACK+=("${p}")
  done
  if [[ "${#TO_PACK[@]}" -gt 0 ]]; then
    # Use paths relative to HOME for portable extract
    (
      cd "${HOME}"
      rel=()
      for p in "${TO_PACK[@]}"; do
        rel+=("${p#"${HOME}"/}")
      done
      tar -czf "${ARCHIVE_OUT}" "${rel[@]}"
    )
    printf 'Archive: %s\n' "${ARCHIVE_OUT}" | tee -a "${OUT}"
    ls -lh "${ARCHIVE_OUT}" | tee -a "${OUT}"
  else
    printf 'No user texmf/latexmk files found to archive.\n' | tee -a "${OUT}"
  fi
fi

printf '\n'
printf 'Report written to:\n  %s\n' "${OUT}"
[[ -n "${ARCHIVE_OUT}" && -f "${ARCHIVE_OUT}" ]] && printf '  %s\n' "${ARCHIVE_OUT}"
[[ -f "${OUT%.txt}-tlmgr-installed.txt" ]] && printf '  %s\n' "${OUT%.txt}-tlmgr-installed.txt"
printf '\nCopy these files to the new machine (e.g. via sftp/scp/USB).\n'
