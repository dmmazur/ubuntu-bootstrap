#!/usr/bin/env bash
# Gather LMTO installation / configuration from a machine that already works.
# Install evidence lives in filesystem + config files (not bash history).
# Copy the generated report (and optional archive) to the new PC for reinstall.
#
# Usage (on the machine WITH LMTO already installed):
#   ./scripts/gather-lmto-setup.sh
#   ./scripts/gather-lmto-setup.sh -o ~/Downloads/lmto-setup-report.txt
#   ./scripts/gather-lmto-setup.sh --archive   # pack key configs (not full ~/src)
#
# Safe: read-only probes + optional tar of small config files (no sudo for most checks).

set -euo pipefail

OUT="${HOME}/Downloads/lmto-setup-report-$(date +%Y%m%d-%H%M%S).txt"
DO_ARCHIVE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) OUT="$2"; shift 2 ;;
    --archive) DO_ARCHIVE=1; shift ;;
    -h|--help)
      sed -n '2,22p' "$0"
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

run_sh() {
  local title="$1"
  local cmd="$2"
  printf '\n--- %s ---\n' "${title}"
  printf '+ %s\n' "${cmd}"
  if ! bash -c "${cmd}" 2>&1; then
    printf '(command failed or not available)\n'
  fi
}

_intel_env() {
  if [[ -f /opt/intel/oneapi/setvars.sh ]]; then
    # shellcheck disable=SC1091
    set +u
    . /opt/intel/oneapi/setvars.sh >/dev/null 2>&1 || true
    set -u
  fi
}

_discover_systemoptions() {
  local root
  for root in "${HOME}" /dep24/"${USER}" /dep24; do
    [[ -d "${root}" ]] || continue
    find "${root}" -maxdepth 8 -path '*/OBJ/*/systemoptions' 2>/dev/null || true
  done | sort -u
}

LSYS="${LSYSTEM:-Linux}"
mapfile -t SYSOPT_PATHS < <(_discover_systemoptions)

{
  section "LMTO setup gather"
  printf 'Host:        %s\n' "$(hostname 2>/dev/null || echo unknown)"
  printf 'User:        %s\n' "$(whoami)"
  printf 'Home:        %s\n' "${HOME}"
  printf 'Date:        %s\n' "$(date -Is)"
  printf 'OS:          %s\n' "$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}")"
  printf 'Kernel:      %s\n' "$(uname -a)"
  printf 'uname -s:    %s\n' "$(uname -s)"
  printf 'LSYSTEM:     %s\n' "${LSYSTEM:-<unset>}"

  section "1) LMTO commands on PATH (wrappers + binaries)"
  for b in \
    lmt lmto orx orxs orp rixs opt fst fsx ibx zbx bbz brx \
    cif2lmt atoms ibz f2u u2f xiq Xscr lmhelp gv make ifx ifort gfortran
  do
    if command -v "${b}" >/dev/null 2>&1; then
      p="$(command -v "${b}")"
      printf '%-12s %s\n' "${b}" "${p}"
      case "${b}" in
        lmto|orx|orxs|ifx|ifort|gfortran)
          "${b}" --version 2>/dev/null | head -3 || file "${p}" 2>/dev/null || true
          ;;
        lmt)
          file "${p}" 2>/dev/null || true
          ;;
      esac
      printf '\n'
    else
      printf '%-12s (not found)\n' "${b}"
    fi
  done

  section "2) lmt wrapper script (full — defines LSYSTEM / SYSBIN)"
  if command -v lmt >/dev/null 2>&1; then
    lmt_path="$(command -v lmt)"
    ls -la "${lmt_path}"
    sed -n '1,120p' "${lmt_path}" 2>/dev/null || true
  else
    for candidate in "${HOME}/bin/lmt" "${HOME}/bin/Linux/lmt"; do
      if [[ -f "${candidate}" ]]; then
        printf 'Found (not on PATH): %s\n' "${candidate}"
        ls -la "${candidate}"
        sed -n '1,120p' "${candidate}" 2>/dev/null || true
        break
      fi
    done
    command -v lmt >/dev/null 2>&1 || echo "lmt not found"
  fi

  section "3) ~/bin layout (scripts + architecture-specific binaries)"
  for d in "${HOME}/bin" "${HOME}/bin/${LSYS}"; do
    if [[ -d "${d}" ]]; then
      printf 'DIR %s\n' "${d}"
      du -sh "${d}" 2>/dev/null || true
      ls -la "${d}" 2>/dev/null | head -80
      printf '\n'
      if [[ "${d}" == "${HOME}/bin/${LSYS}" ]]; then
        run_sh "lmto symlinks / versions" \
          "ls -la \"${d}\"/lmto* 2>/dev/null; readlink -f \"${d}/lmto\" 2>/dev/null || true"
      fi
    else
      printf 'absent %s\n' "${d}"
    fi
  done
  run_sh "Other LSYSTEM dirs under ~/bin" \
    'ls -d "${HOME}/bin"/*/ 2>/dev/null | grep -v "/bin/Linux/" || true'

  section "4) ~/lib layout"
  for d in "${HOME}/lib" "${HOME}/lib/${LSYS}" "${HOME}/lib/LMHELP"; do
    if [[ -e "${d}" ]]; then
      printf 'FOUND %s\n' "${d}"
      du -sh "${d}" 2>/dev/null || true
      ls -la "${d}" 2>/dev/null | head -60
      printf '\n'
    else
      printf 'absent %s\n' "${d}"
    fi
  done

  section "5) LMTO source tree discovery (configure / Readme.1st)"
  run_sh "Well-known source paths" \
    'for p in "${HOME}/src" "${HOME}/repos/lmto" "${HOME}/lmto" "/dep24/${USER}/src"; do
       [[ -e "$p" ]] && printf "%s\n" "$p" && ls -la "$p" | head -15
     done'
  run_sh "find configure scripts under home + /dep24 (maxdepth 6)" \
    'for root in "${HOME}" /dep24/"${USER}" /dep24; do
       [[ -d "$root" ]] || continue
       find "$root" -maxdepth 6 \( -name configure -path "*/src/configure" -o -name configure \) 2>/dev/null
     done | sort -u | head -30'
  run_sh "find Readme.1st (LMTO package marker)" \
    'for root in "${HOME}" /dep24/"${USER}" /dep24; do
       [[ -d "$root" ]] || continue
       find "$root" -maxdepth 6 -name Readme.1st 2>/dev/null | head -20
     done | sort -u'
  run_sh "find systemoptions (build config — key for reinstall)" \
    'for root in "${HOME}" /dep24/"${USER}" /dep24; do
       [[ -d "$root" ]] || continue
       find "$root" -maxdepth 8 -path "*/OBJ/*/systemoptions" -o -maxdepth 8 -name systemoptions 2>/dev/null
     done | sort -u | head -30'

  section "6) systemoptions + localoptions (per OBJ tree found)"
  if [[ "${#SYSOPT_PATHS[@]}" -eq 0 ]]; then
    echo "No systemoptions files found — LMTO may not be built or source is on NFS only."
  else
    for so in "${SYSOPT_PATHS[@]}"; do
      printf '\n>>> %s\n' "${so}"
      cat "${so}" 2>/dev/null || true
      lo="$(dirname "${so}")/localoptions"
      if [[ -f "${lo}" ]]; then
        printf '\n--- localoptions: %s ---\n' "${lo}"
        ls -la "${lo}"
        sed -n '1,120p' "${lo}" 2>/dev/null || true
      else
        printf '\n(no localoptions next to %s)\n' "${so}"
      fi
      src_top="$(dirname "$(dirname "$(dirname "${so}")")")"
      printf '\n--- source tree top (%s) ---\n' "${src_top}"
      ls -la "${src_top}" 2>/dev/null | head -25 || true
      if [[ -d "${src_top}/MAK" ]]; then
        printf '\n--- MAK/ makefiles ---\n'
        ls -la "${src_top}/MAK" 2>/dev/null | head -40 || true
      fi
    done
  fi

  section "7) Intel oneAPI / Fortran compiler"
  run_sh "setvars.sh" 'ls -la /opt/intel/oneapi/setvars.sh 2>/dev/null || echo "(missing)"'
  run_sh "Intel install tree (top level)" 'ls -la /opt/intel/oneapi 2>/dev/null | head -40 || echo "(missing)"'
  run_sh "Compiler versions under /opt/intel/oneapi/compiler" \
    'ls -la /opt/intel/oneapi/compiler 2>/dev/null; for d in /opt/intel/oneapi/compiler/*/bin/ifx; do
       [[ -x "$d" ]] && echo "$d" && "$d" --version 2>/dev/null | head -3
     done'
  _intel_env
  run_sh "ifx / ifort / icx after setvars" \
    'command -v ifx 2>/dev/null; ifx --version 2>/dev/null | head -3 || true
     command -v ifort 2>/dev/null; ifort --version 2>/dev/null | head -2 || true'
  run_sh "MKL root" 'ls -la /opt/intel/oneapi/mkl 2>/dev/null | head -20 || echo "(missing)"'
  run_sh "Intel offline installers (if still on disk)" \
    'find /opt /home /tmp /dep24/"${USER}" -maxdepth 4 -name "*offline.sh" 2>/dev/null | head -20'
  run_sh "Intel installer metadata" \
    'ls -la /opt/intel/oneapi/installer 2>/dev/null | head -20 || true
     cat /opt/intel/oneapi/installer/installer.json 2>/dev/null | head -40 || true'

  section "8) APT: Intel oneAPI + LMTO build prerequisites"
  if command -v dpkg-query >/dev/null 2>&1; then
    run_sh "Intel oneAPI apt packages" \
      "dpkg-query -W -f='\${Status}\t\${Package}\t\${Version}\n' 2>/dev/null \
        | awk '/^install ok installed/ && \$2 ~ /^intel-oneapi/ {print}' | sort"
    run_sh "LMTO-related apt packages (build, nfs, fortran, texinfo, gv)" \
      "dpkg-query -W -f='\${Status}\t\${Package}\t\${Version}\n' 2>/dev/null \
        | awk '/^install ok installed/ && \$2 ~ /^(build-essential|gfortran|make|nfs-common|texinfo|gv|libx11|libxext|curl|wget|git)/ {print}' | sort"
    run_sh "apt-mark showmanual (intel + lmto-related)" \
      "apt-mark showmanual 2>/dev/null | grep -iE 'intel-oneapi|gfortran|nfs-common|texinfo|build-essential' | sort"
    run_sh "Intel apt repo files" \
      'ls -la /etc/apt/sources.list.d/oneAPI.list /usr/share/keyrings/oneapi-archive-keyring.gpg 2>/dev/null || true
       grep -r intel /etc/apt/sources.list.d/ 2>/dev/null || true'
  fi

  section "9) Environment: profile, profile.d, LMTO-related exports"
  printf 'Current shell (LMTO-related env):\n'
  env | grep -iE '^(LSYSTEM|PATH|MKL|INTEL|OMP|KMP)_' | sort || true
  printf '\n--- profile / bashrc / profile.d lines ---\n'
  for f in \
    "${HOME}/.profile" "${HOME}/.bash_profile" "${HOME}/.bashrc" \
    "${HOME}/.zshrc" /etc/profile.d/lmto.sh /etc/profile.d/*lmto* /etc/environment
  do
    [[ -e "${f}" ]] || continue
    if grep -nEi 'setvars|LSYSTEM|/bin|LMTO|MKL|INTEL|oneapi|lmto' "${f}" 2>/dev/null; then
      printf '# from %s\n' "${f}"
      grep -nEi 'setvars|LSYSTEM|/bin|LMTO|MKL|INTEL|oneapi|lmto' "${f}" 2>/dev/null || true
      printf '\n'
    fi
  done
  if [[ -f /etc/profile.d/lmto.sh ]]; then
    printf '\n--- full /etc/profile.d/lmto.sh ---\n'
    cat /etc/profile.d/lmto.sh
  fi

  section "10) NFS /dep24 and home convenience symlinks"
  run_sh "fstab dep24 / nfs lines" \
    "grep -iE 'dep24|nfs' /etc/fstab 2>/dev/null || true"
  run_sh "findmnt / df dep24" \
    'findmnt 2>/dev/null | grep -iE dep24 || true
     df -h /dep24 2>/dev/null || true'
  run_sh "home symlinks (dep24, R, TeX)" \
    "ls -la \"${HOME}\" 2>/dev/null | grep -iE 'dep24|TeX|R_dep' || true
     for l in dep24 R_dep24 TeX_dep24 src; do
       [[ -e \"${HOME}/\$l\" ]] && ls -la \"${HOME}/\$l\"
     done"
  run_sh "Is ~/src a symlink?" \
    "ls -la \"${HOME}/src\" 2>/dev/null || echo '(no ~/src)'"

  section "11) Scratch / build directories"
  for d in /scratch "${HOME}/scratch" /tmp; do
    if [[ -d "${d}" ]]; then
      printf 'DIR %s  mode=%s\n' "${d}" "$(stat -c '%a' "${d}" 2>/dev/null || echo '?')"
      ls -la "${d}" 2>/dev/null | head -20 || true
      printf '\n'
    fi
  done

  section "12) Filesystem clues (install / build evidence — not bash history)"
  run_sh "configure.log / make logs near source trees" \
    'for root in "${HOME}/src" "${HOME}/repos/lmto" /dep24/"${USER}/src"; do
       [[ -d "$root" ]] || continue
       find "$root" -maxdepth 3 \( -name "configure.log" -o -name "make.log" -o -name "*.log" \) 2>/dev/null | head -20
     done'
  run_sh "OBJ build dirs (sizes)" \
    'for root in "${HOME}/src" "${HOME}/repos/lmto"; do
       [[ -d "$root/OBJ" ]] || continue
       du -sh "$root/OBJ"/* 2>/dev/null | head -20
     done'
  run_sh "Packaged LMTO tarballs under home / dep24" \
    'find "${HOME}" /dep24/"${USER}" -maxdepth 4 \( -iname "*lmto*.tar*" -o -iname "*LMTO*.tar*" \) 2>/dev/null | head -20'

  section "13) Shell history — LMTO usage only (not install recipe)"
  printf 'History shows how LMTO was *used* (lmt, orx, etc.), not how it was installed.\n'
  for hf in "${HOME}/.bash_history" "${HOME}/.zsh_history"; do
    [[ -f "${hf}" ]] || continue
    printf '# from %s\n' "${hf}"
    grep -iE '\blmt\b|\borx\b|\borxs\b|\borp\b|\brixs\b|lmto|cif2lmt|/dep24/|SRCTOP|configure|ifx_mkl' "${hf}" 2>/dev/null | tail -60 || true
    printf '\n'
  done

  section "14) Suggested reinstall mapping (generated)"
  cat <<'EOF'
On the NEW machine (ubuntu-bootstrap):

A) Copy LMTO source tree
   - rsync/scp the SRCTOP directory from section 6 (usually ~/src) to ~/src on the new PC.
   - Expected: ~/src/configure, ~/src/MAK/ifx_mkl.mak, ~/src/LMTO/, Readme.1st

B) Intel oneAPI (apt — preferred in this repo)
   sudo apt install intel-oneapi-compiler-fortran intel-oneapi-mkl-devel
   source /opt/intel/oneapi/setvars.sh
   # Or use: ./scripts/bootstrap-lmto.sh

C) Match build options from systemoptions / localoptions (section 6)
   - Makefile: typically MAK/ifx_mkl.mak
   - LSYSTEM: usually Linux (from uname)
   - FFLAGS: note -xHost in localoptions if present
   - Output: ~/bin/Linux, ~/lib/Linux, ~/lib/LMHELP

D) Environment
   - ~/.profile should source setvars.sh (section 9)
   - /etc/profile.d/lmto.sh adds ~/bin and ~/bin/$LSYSTEM to PATH

E) NFS (if institute network)
   - Re-create fstab line from section 10
   - Symlinks ~/dep24, ~/R_dep24, ~/TeX_dep24 when /dep24 is mounted

F) Verify on new machine
   ./scripts/verify-lmto.sh
   lmt -h   # or a small test case
   ifx --version

G) Optional: restore small configs from --archive (lmt, systemoptions, localoptions)
   Do NOT skip copying ~/src — binaries alone are not enough to rebuild.
EOF

  section "15) One-line summary for group_vars tuning"
  src_guess="${HOME}/src"
  if [[ "${#SYSOPT_PATHS[@]}" -gt 0 ]]; then
  # shellcheck disable=SC2001
    src_guess="$(sed 's|/OBJ/.*||' <<<"${SYSOPT_PATHS[0]}")"
  fi
  makefile_guess="ifx_mkl.mak"
  if [[ "${#SYSOPT_PATHS[@]}" -gt 0 ]]; then
    mak_line="$(grep -E '^SYSMAK=' "${SYSOPT_PATHS[0]}" 2>/dev/null | head -1 || true)"
    if [[ -n "${mak_line}" ]]; then
      makefile_guess="$(basename "${mak_line#SYSMAK=}")"
    fi
  fi
  lmto_ver=""
  if [[ -L "${HOME}/bin/${LSYS}/lmto" ]]; then
    lmto_ver="$(readlink "${HOME}/bin/${LSYS}/lmto" 2>/dev/null || true)"
  fi
  printf 'lmto_src_dir:           %s\n' "${src_guess}"
  printf 'lmto_lsystem:           %s\n' "${LSYS}"
  printf 'lmto_makefile_intel:    %s\n' "${makefile_guess}"
  printf 'lmto_enable_xhost:      check localoptions FFLAGS for -xHost\n'
  printf 'lmto binary version:    %s\n' "${lmto_ver:-unknown}"
  printf 'intel setvars:          /opt/intel/oneapi/setvars.sh\n'
  if grep -q dep24 /etc/fstab 2>/dev/null; then
    grep dep24 /etc/fstab | head -1
  else
    printf 'nfs:                    (no dep24 in fstab on this host)\n'
  fi

} | tee "${OUT}"

ARCHIVE_OUT=""
if [[ "${DO_ARCHIVE}" -eq 1 ]]; then
  ARCHIVE_OUT="${OUT%.txt}-configs.tgz"
  section "Creating LMTO config archive (not full source tree)" | tee -a "${OUT}"
  TO_PACK=()
  for p in \
    "${HOME}/bin/lmt" \
    /etc/profile.d/lmto.sh
  do
    [[ -e "${p}" ]] && TO_PACK+=("${p}")
  done
  for so in "${SYSOPT_PATHS[@]}"; do
    [[ -f "${so}" ]] && TO_PACK+=("${so}")
    lo="$(dirname "${so}")/localoptions"
    [[ -f "${lo}" ]] && TO_PACK+=("${lo}")
  done
  # Unique paths only
  mapfile -t TO_PACK < <(printf '%s\n' "${TO_PACK[@]}" | sort -u)
  if [[ "${#TO_PACK[@]}" -gt 0 ]]; then
    tar -czf "${ARCHIVE_OUT}" --ignore-failed-read "${TO_PACK[@]}" 2>/dev/null || \
      tar -czf "${ARCHIVE_OUT}" "${TO_PACK[@]}"
    printf 'Archive: %s\n' "${ARCHIVE_OUT}" | tee -a "${OUT}"
    ls -lh "${ARCHIVE_OUT}" | tee -a "${OUT}"
    printf 'Contents:\n' | tee -a "${OUT}"
    tar -tzf "${ARCHIVE_OUT}" 2>/dev/null | tee -a "${OUT}" || true
  else
    printf 'No LMTO config files found to archive.\n' | tee -a "${OUT}"
  fi
fi

printf '\n'
printf 'Report written to:\n  %s\n' "${OUT}"
[[ -n "${ARCHIVE_OUT}" && -f "${ARCHIVE_OUT}" ]] && printf '  %s\n' "${ARCHIVE_OUT}"
printf '\nCopy report (+ archive) to the new machine. Copy ~/src separately (rsync).\n'
