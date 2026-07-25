#!/usr/bin/env bash
# Shared helpers for install-status verification scripts.
# Reads expected items from group_vars/all.yml (no Ansible required).

set -euo pipefail

# Repo root = parent of scripts/ (this file lives in scripts/verify/)
VERIFY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GROUP_VARS="${VERIFY_ROOT}/group_vars/all.yml"
HOME_DIR="${HOME}"
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  HOME_DIR="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
fi

OK_COUNT=0
MISSING_COUNT=0
SKIPPED_COUNT=0
WARN_COUNT=0

# Colors only if stdout is a TTY
if [[ -t 1 ]]; then
  C_OK=$'\033[32m'
  C_MISS=$'\033[31m'
  C_SKIP=$'\033[33m'
  C_WARN=$'\033[33m'
  C_RST=$'\033[0m'
else
  C_OK= C_MISS= C_SKIP= C_WARN= C_RST=
fi

ok() {
  printf '  %sOK%s      %s\n' "${C_OK}" "${C_RST}" "$*"
  OK_COUNT=$((OK_COUNT + 1))
}

missing() {
  printf '  %sMISSING%s %s\n' "${C_MISS}" "${C_RST}" "$*"
  MISSING_COUNT=$((MISSING_COUNT + 1))
}

skipped() {
  printf '  %sSKIP%s    %s\n' "${C_SKIP}" "${C_RST}" "$*"
  SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
}

warn() {
  printf '  %sWARN%s    %s\n' "${C_WARN}" "${C_RST}" "$*"
  WARN_COUNT=$((WARN_COUNT + 1))
}

section() {
  printf '\n==> %s\n' "$*"
}

yaml_bool() {
  # yaml_bool KEY  -> prints true|false|empty
  local key="$1"
  local line
  line="$(grep -E "^${key}:" "${GROUP_VARS}" | head -1 || true)"
  if [[ -z "${line}" ]]; then
    echo ""
    return
  fi
  if echo "${line}" | grep -qiE ':[[:space:]]*true([[:space:]]|#|$)'; then
    echo "true"
  else
    echo "false"
  fi
}

yaml_scalar() {
  # yaml_scalar KEY -> value after first :
  local key="$1"
  awk -v k="${key}" '
    $0 ~ "^" k ":" {
      sub("^[^:]+:[[:space:]]*", "")
      sub("[[:space:]]*#.*$", "")
      gsub(/^"/, ""); gsub(/"$/, "")
      print
      exit
    }
  ' "${GROUP_VARS}"
}

yaml_list() {
  # yaml_list KEY -> one item per line (simple "- name" list)
  local key="$1"
  awk -v k="${key}" '
    BEGIN { inlist=0 }
    $0 ~ "^" k ":" { inlist=1; next }
    inlist && /^[^[:space:]#]/ { exit }
    inlist && /^[[:space:]]+-[[:space:]]+/ {
      line=$0
      sub(/^[[:space:]]+-[[:space:]]+/, "", line)
      sub(/[[:space:]]*#.*$/, "", line)
      gsub(/^"/, "", line); gsub(/"$/, "", line)
      # skip map keys like "name: code"
      if (line ~ /^name:[[:space:]]*/) {
        sub(/^name:[[:space:]]*/, "", line)
        gsub(/^"/, "", line); gsub(/"$/, "", line)
        print line
      } else if (line !~ /:/) {
        print line
      }
      next
    }
    inlist && /^[[:space:]]+name:[[:space:]]+/ {
      line=$0
      sub(/^[[:space:]]+name:[[:space:]]*/, "", line)
      sub(/[[:space:]]*#.*$/, "", line)
      gsub(/^"/, "", line); gsub(/"$/, "", line)
      print line
      next
    }
  ' "${GROUP_VARS}"
}

check_apt() {
  local pkg="$1"
  if dpkg-query -W -f='${Status}' "${pkg}" 2>/dev/null | grep -q 'install ok installed'; then
    local ver
    ver="$(dpkg-query -W -f='${Version}' "${pkg}" 2>/dev/null || true)"
    ok "apt ${pkg} (${ver})"
  else
    missing "apt ${pkg}"
  fi
}

check_snap() {
  local name="$1"
  if snap list "${name}" &>/dev/null; then
    local ver
    ver="$(snap list "${name}" 2>/dev/null | awk 'NR==2 {print $2}')"
    ok "snap ${name}${ver:+ (${ver})}"
  else
    missing "snap ${name}"
  fi
}

check_flatpak() {
  local app="$1"
  if command -v flatpak >/dev/null 2>&1 && flatpak info "${app}" &>/dev/null; then
    ok "flatpak ${app}"
  else
    missing "flatpak ${app}"
  fi
}

check_cmd() {
  local label="$1"
  local cmd="$2"
  if command -v "${cmd}" >/dev/null 2>&1; then
    ok "${label}: $(command -v "${cmd}")"
  else
    missing "${label}: command '${cmd}' not in PATH"
  fi
}

check_file() {
  local label="$1"
  local path="$2"
  if [[ -e "${path}" || -L "${path}" ]]; then
    if [[ -L "${path}" ]]; then
      ok "${label}: ${path} -> $(readlink -f "${path}" 2>/dev/null || readlink "${path}")"
    else
      ok "${label}: ${path}"
    fi
  else
    missing "${label}: ${path}"
  fi
}

check_symlink() {
  local label="$1"
  local path="$2"
  local expect_target="${3:-}"
  if [[ -L "${path}" ]]; then
    local tgt
    tgt="$(readlink "${path}")"
    if [[ -n "${expect_target}" && "${tgt}" != "${expect_target}" ]]; then
      warn "${label}: ${path} -> ${tgt} (expected ${expect_target})"
    else
      ok "${label}: ${path} -> ${tgt}"
    fi
  elif [[ -e "${path}" ]]; then
    warn "${label}: ${path} exists but is not a symlink"
  else
    missing "${label}: ${path}"
  fi
}

print_summary() {
  printf '\n----------------------------------------\n'
  printf 'Summary: %sOK%s=%d  %sMISSING%s=%d  %sSKIP%s=%d  %sWARN%s=%d\n' \
    "${C_OK}" "${C_RST}" "${OK_COUNT}" \
    "${C_MISS}" "${C_RST}" "${MISSING_COUNT}" \
    "${C_SKIP}" "${C_RST}" "${SKIPPED_COUNT}" \
    "${C_WARN}" "${C_RST}" "${WARN_COUNT}"
  if [[ "${MISSING_COUNT}" -gt 0 ]]; then
    return 1
  fi
  return 0
}

verify_common() {
  section "common (apt packages)"
  local pkg
  while IFS= read -r pkg; do
    [[ -z "${pkg}" ]] && continue
    check_apt "${pkg}"
  done < <(yaml_list apt_packages_common)
}

verify_lab() {
  section "lab (apt packages)"
  if [[ "$(yaml_bool enable_lab_packages)" != "true" ]]; then
    skipped "enable_lab_packages is false — not expected"
    return 0
  fi
  local pkg
  local on_wsl=0
  if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null \
    || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null \
    || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    on_wsl=1
  fi
  while IFS= read -r pkg; do
    [[ -z "${pkg}" ]] && continue
    if [[ "${on_wsl}" -eq 1 && "${pkg}" == "openssh-server" ]]; then
      skipped "openssh-server (skipped on WSL)"
      continue
    fi
    check_apt "${pkg}"
  done < <(yaml_list apt_packages_lab)
}

verify_experimental() {
  section "experimental (apt packages)"
  if [[ "$(yaml_bool install_experimental)" != "true" ]]; then
    skipped "install_experimental is false — section disabled"
    return 0
  fi
  local pkg
  while IFS= read -r pkg; do
    [[ -z "${pkg}" ]] && continue
    check_apt "${pkg}"
  done < <(yaml_list apt_packages_experimental)
}

verify_latex() {
  section "latex"
  if [[ "$(yaml_bool install_latex)" != "true" ]]; then
    skipped "install_latex is false — section disabled"
    return 0
  fi

  section "latex-apt"
  if [[ "$(yaml_bool latex_install_apt)" == "true" ]]; then
    local pkg
    while IFS= read -r pkg; do
      [[ -z "${pkg}" ]] && continue
      check_apt "${pkg}"
    done < <(yaml_list apt_packages_latex)
    if command -v pdflatex >/dev/null 2>&1; then
      ok "pdflatex: $(command -v pdflatex)"
    else
      missing "pdflatex not on PATH"
    fi
    if command -v kpsewhich >/dev/null 2>&1 && kpsewhich article.cls >/dev/null 2>&1; then
      ok "kpsewhich article.cls → $(kpsewhich article.cls)"
    else
      missing "kpsewhich article.cls failed"
    fi
    if command -v latexmk >/dev/null 2>&1; then
      ok "latexmk: $(command -v latexmk)"
    else
      missing "latexmk not on PATH"
    fi
    if command -v biber >/dev/null 2>&1; then
      ok "biber: $(command -v biber)"
    else
      missing "biber not on PATH"
    fi
  else
    skipped "latex_install_apt is false"
  fi

  section "latex-texmf"
  if [[ "$(yaml_bool latex_ensure_texmf)" == "true" ]]; then
    check_file "TEXMFHOME ~/texmf" "${HOME_DIR}/texmf"
    check_file "~/texmf/tex/latex" "${HOME_DIR}/texmf/tex/latex"
  else
    skipped "latex_ensure_texmf is false"
  fi

  section "latex-smoke"
  if [[ "$(yaml_bool latex_run_smoke)" == "true" ]]; then
    check_file "smoke.pdf" "${HOME_DIR}/TeX/smoke/smoke.pdf"
  else
    skipped "latex_run_smoke is false"
  fi
}

verify_latex_editors() {
  section "latex-editors"
  if [[ "$(yaml_bool install_latex_editors)" != "true" ]]; then
    skipped "install_latex_editors is false — section disabled"
    return 0
  fi

  local ext
  ext="$(yaml_scalar latex_workshop_extension_id)"
  [[ -z "${ext}" ]] && ext="James-Yu.latex-workshop"

  _check_editor_ext() {
    local cli="$1" label="$2"
    if ! command -v "${cli}" >/dev/null 2>&1; then
      skipped "${label}: ${cli} CLI not installed — extension not expected"
      return 0
    fi
    if "${cli}" --list-extensions 2>/dev/null | grep -qi "^${ext}$"; then
      ok "${label}: ${ext}"
    else
      # Fallback: extension dir naming (james-yu.latex-workshop-*)
      local dir
      case "${cli}" in
        code) dir="${HOME_DIR}/.vscode/extensions" ;;
        cursor) dir="${HOME_DIR}/.cursor/extensions" ;;
        *) dir="" ;;
      esac
      if [[ -n "${dir}" ]] && {
           compgen -G "${dir}/james-yu.latex-workshop-*" >/dev/null 2>&1 \
           || compgen -G "${dir}/James-Yu.latex-workshop-*" >/dev/null 2>&1
         }; then
        ok "${label}: ${ext} (found under ${dir})"
      else
        missing "${label}: ${ext} not installed (run ./scripts/bootstrap/bootstrap-latex-editors.sh)"
      fi
    fi
  }

  _check_editor_ext code "VS Code"
  _check_editor_ext cursor "Cursor"
}

verify_snaps() {
  section "snaps"
  if [[ "$(yaml_bool install_snaps)" != "true" ]]; then
    skipped "install_snaps is false — section disabled"
    return 0
  fi
  if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null \
    || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null \
    || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    if [[ "$(yaml_bool install_snaps_on_wsl)" != "true" ]]; then
      skipped "WSL: snaps skipped by default (install_snaps_on_wsl: false)"
      return 0
    fi
  fi
  local name
  while IFS= read -r name; do
    [[ -z "${name}" ]] && continue
    check_snap "${name}"
  done < <(yaml_list snaps)
}

verify_flatpak() {
  section "flatpak"
  if [[ "$(yaml_bool install_flatpak)" != "true" ]]; then
    skipped "install_flatpak is false — section disabled"
    return 0
  fi
  local app
  while IFS= read -r app; do
    [[ -z "${app}" ]] && continue
    check_flatpak "${app}"
  done < <(yaml_list flatpaks)
}

verify_debs() {
  section "debs (Cursor / VeraCrypt)"
  if [[ "$(yaml_bool install_debs)" != "true" ]]; then
    skipped "install_debs is false — section disabled"
    # Still report if packages happen to be present
    if dpkg-query -W -f='${Status}' cursor 2>/dev/null | grep -q 'install ok installed'; then
      ok "apt cursor (present even though install_debs is off)"
    fi
    if dpkg-query -W -f='${Status}' veracrypt 2>/dev/null | grep -q 'install ok installed'; then
      ok "apt veracrypt (present even though install_debs is off)"
    fi
    return 0
  fi
  check_apt cursor
  check_apt veracrypt
}

verify_claude() {
  section "claude-desktop"
  if [[ "$(yaml_bool install_claude_desktop)" != "true" ]]; then
    skipped "install_claude_desktop is false — section disabled"
    return 0
  fi
  local keyring list
  keyring="$(yaml_scalar claude_desktop_keyring)"
  list="$(yaml_scalar claude_desktop_list)"
  check_file "Claude apt keyring" "${keyring}"
  check_file "Claude apt list" "${list}"
  check_apt claude-desktop
  check_cmd "claude-desktop binary" claude-desktop || true
}

verify_chrome() {
  section "google-chrome"
  if [[ "$(yaml_bool install_google_chrome)" != "true" ]]; then
    skipped "install_google_chrome is false — section disabled"
    return 0
  fi
  local keyring list
  keyring="$(yaml_scalar chrome_keyring)"
  list="$(yaml_scalar chrome_list)"
  check_file "Chrome apt keyring" "${keyring}"
  check_file "Chrome apt list" "${list}"
  check_apt google-chrome-stable
}

verify_lmto_ui() {
  section "lmto-ui"
  if [[ "$(yaml_bool install_lmto_ui)" != "true" ]]; then
    skipped "install_lmto_ui is false — section disabled"
    return 0
  fi
  local repo project csproj unit url
  repo="$(yaml_scalar lmto_ui_repo)"
  # group_vars uses Jinja — resolve ~ / home
  repo="${repo//\{\{ bootstrap_home \}\}/${HOME_DIR}}"
  repo="${repo//\"/}"
  [[ "${repo}" == *"{{"* ]] && repo="${HOME_DIR}/repos/lmto-ui"
  project="${repo}/src/LmtoUi"
  csproj="${project}/LmtoUi.csproj"
  unit="${HOME_DIR}/.config/systemd/user/lmto-ui.service"
  url="$(yaml_scalar lmto_ui_url)"
  [[ -z "${url}" || "${url}" == *"{{"* ]] && url="http://127.0.0.1:5100"

  check_file "LmtoUi.csproj" "${csproj}"
  if [[ -f "${unit}" ]]; then
    ok "systemd user unit: ${unit}"
  else
    missing "systemd user unit: ${unit}"
  fi
  local uid runtime
  uid="$(id -u)"
  runtime="/run/user/${uid}"
  if [[ -d "${runtime}" ]] && systemctl --user is-active lmto-ui &>/dev/null; then
    ok "lmto-ui user service active → ${url}"
  elif [[ -d "${runtime}" ]]; then
    missing "lmto-ui user service not active (systemctl --user status lmto-ui)"
  else
    skipped "user systemd runtime missing — start with: cd ${repo} && dotnet run --project src/LmtoUi"
  fi
}

verify_dotnet() {
  section "dotnet-sdk"
  if [[ "$(yaml_bool install_dotnet_sdk)" != "true" ]]; then
    skipped "install_dotnet_sdk is false — section disabled"
    return 0
  fi
  local pkg ver min_ver
  pkg="$(yaml_scalar dotnet_sdk_package)"
  ver="$(yaml_scalar dotnet_sdk_version)"
  min_ver="$(yaml_scalar dotnet_backports_min_ubuntu)"
  [[ -z "${pkg}" ]] && pkg="dotnet-sdk-8.0"
  [[ -z "${ver}" ]] && ver="8.0"
  [[ -z "${min_ver}" ]] && min_ver="26.04"
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
  fi
  if [[ "${ID:-}" == "ubuntu" ]] && dpkg --compare-versions "${VERSION_ID:-0}" ge "${min_ver}"; then
    if grep -rqE 'dotnet/backports|ppa\.launchpadcontent\.net/dotnet/backports' \
      /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
      ok "dotnet backports PPA configured (needed for .NET 8 on Ubuntu ${VERSION_ID})"
    else
      missing "dotnet backports PPA missing (Ubuntu ${VERSION_ID} needs ppa:dotnet/backports for .NET 8)"
    fi
  fi
  check_apt "${pkg}"
  if check_cmd "dotnet CLI" dotnet; then
    if dotnet --list-sdks 2>/dev/null | grep -qE "^${ver}"; then
      ok "dotnet SDK ${ver} listed"
    else
      missing "dotnet SDK ${ver} not in: $(dotnet --list-sdks 2>/dev/null | tr '\n' ' ')"
    fi
  fi
}

verify_ollama() {
  section "ollama"
  if [[ "$(yaml_bool install_ollama)" != "true" ]]; then
    skipped "install_ollama is false — section disabled"
    return 0
  fi
  check_file "ollama binary" /usr/bin/ollama
  check_file "ollama unit" /etc/systemd/system/ollama.service
  if systemctl is-enabled ollama &>/dev/null; then
    ok "systemd ollama enabled"
  else
    missing "systemd ollama not enabled"
  fi
  if systemctl is-active ollama &>/dev/null; then
    ok "systemd ollama active"
  else
    missing "systemd ollama not active"
  fi
}

verify_lmto() {
  section "lmto"
  if [[ "$(yaml_bool install_lmto)" != "true" ]]; then
    skipped "install_lmto is false — section disabled"
    return 0
  fi

  local pkg src_dir lsystem setvars profile_script scratch
  src_dir="${HOME_DIR}/src"
  lsystem="$(yaml_scalar lmto_lsystem)"
  [[ -z "${lsystem}" ]] && lsystem=ifx
  setvars="$(yaml_scalar lmto_intel_setvars)"

  section "lmto-intel"
  if [[ "$(yaml_bool lmto_install_intel)" == "true" ]]; then
    if [[ "$(yaml_bool lmto_install_intel_fortran_apt)" == "true" ]]; then
      check_apt "$(yaml_scalar lmto_intel_fortran_package)"
    fi
    if [[ "$(yaml_bool lmto_install_intel_mkl_apt)" == "true" ]]; then
      check_apt "$(yaml_scalar lmto_intel_mkl_package)"
    fi
    check_file "Intel oneAPI apt keyring" "$(yaml_scalar intel_oneapi_keyring)"
    check_file "Intel oneAPI apt list" "$(yaml_scalar intel_oneapi_list)"
    check_file "Intel setvars.sh" "${setvars}"
    profile_script="$(yaml_scalar lmto_profile_script)"
    check_file "LMTO profile.d script" "${profile_script}"
    if [[ "$(yaml_bool lmto_ensure_bashrc_lsystem)" == "true" ]]; then
      if grep -qE "export[[:space:]]+LSYSTEM=${lsystem}" "${HOME_DIR}/.bashrc" 2>/dev/null; then
        ok "~/.bashrc exports LSYSTEM=${lsystem}"
      else
        missing "~/.bashrc missing: export LSYSTEM=${lsystem}"
      fi
    fi
    if [[ "$(yaml_bool lmto_ensure_bashrc_setvars)" == "true" ]]; then
      if grep -qE 'setvars\.sh' "${HOME_DIR}/.bashrc" 2>/dev/null; then
        ok "~/.bashrc sources setvars"
      else
        missing "~/.bashrc does not source setvars.sh"
      fi
    fi
    if [[ "$(yaml_bool lmto_ensure_user_profile_setvars)" == "true" ]]; then
      if grep -qE 'setvars\.sh' "${HOME_DIR}/.profile" 2>/dev/null; then
        ok "~/.profile sources setvars"
      else
        missing "~/.profile does not source setvars.sh"
      fi
    else
      skipped "~/.profile setvars (lmto_ensure_user_profile_setvars is false)"
    fi
  else
    skipped "lmto_install_intel is false"
  fi

  section "lmto-unpack"
  if [[ "$(yaml_bool lmto_unpack_archives)" == "true" ]]; then
    check_file "LMTO source ~/src/configure" "${src_dir}/configure"
    check_file "LMTO makefile ifx_mkl" "${src_dir}/MAK/ifx_mkl.mak"
    check_file "~/bin (scripts)" "${HOME_DIR}/bin"
    check_file "~/bin/${lsystem}" "${HOME_DIR}/bin/${lsystem}"
    check_file "~/lib/${lsystem}" "${HOME_DIR}/lib/${lsystem}"
  else
    skipped "lmto_unpack_archives is false"
  fi

  section "lmto-build"
  if [[ "$(yaml_bool lmto_build)" == "true" ]]; then
    while IFS= read -r pkg; do
      [[ -z "${pkg}" ]] && continue
      check_apt "${pkg}"
    done < <(yaml_list apt_packages_lmto)

    if [[ "$(yaml_bool lmto_scratch_enable)" == "true" ]]; then
      scratch="$(yaml_scalar lmto_scratch_dir)"
      check_file "scratch dir" "${scratch}"
    else
      skipped "scratch dir (lmto_scratch_enable is false)"
    fi

    check_file "OBJ/${lsystem}/systemoptions" "${src_dir}/OBJ/${lsystem}/systemoptions"
    if [[ -x "${HOME_DIR}/bin/lmt" ]]; then
      ok "lmt wrapper: ${HOME_DIR}/bin/lmt"
    else
      missing "lmt wrapper: ${HOME_DIR}/bin/lmt"
    fi
    if [[ -e "${HOME_DIR}/bin/${lsystem}/lmto" || -L "${HOME_DIR}/bin/${lsystem}/lmto" ]]; then
      ok "lmto binary: ${HOME_DIR}/bin/${lsystem}/lmto"
    else
      missing "lmto binary: ${HOME_DIR}/bin/${lsystem}/lmto"
    fi
  else
    skipped "lmto_build is false"
  fi

  section "lmto-xscr"
  if [[ "$(yaml_bool lmto_install_xscr)" == "true" ]]; then
    local bin
    # Defaults match group_vars lmto_xscr_binaries
    for bin in Xscr grf2eps grfonts; do
      if [[ -x "${HOME_DIR}/bin/${bin}" ]]; then
        ok "~/bin/${bin}"
      else
        missing "~/bin/${bin}"
      fi
      if [[ -e "${HOME_DIR}/bin/${lsystem}/${bin}" || -L "${HOME_DIR}/bin/${lsystem}/${bin}" ]]; then
        ok "~/bin/${lsystem}/${bin}"
      else
        missing "~/bin/${lsystem}/${bin}"
      fi
    done
  else
    skipped "lmto_install_xscr is false"
  fi

  section "lmto-rdir"
  if [[ "$(yaml_bool lmto_create_r_dir)" == "true" ]]; then
    check_file "LMTO cases dir ~/R" "${HOME_DIR}/R"
  else
    skipped "lmto_create_r_dir is false"
  fi

  section "lmto-test"
  if [[ "$(yaml_bool lmto_run_fe_test)" == "true" ]]; then
    local compound ini
    compound="$(yaml_scalar lmto_test_compound)"
    ini="$(yaml_scalar lmto_test_ini)"
    [[ -z "${compound}" ]] && compound=Fe
    [[ -z "${ini}" ]] && ini=lmt.lmt
    check_file "Fe case dir" "${HOME_DIR}/R/${compound}"
    check_file "${ini}" "${HOME_DIR}/R/${compound}/${ini}"
  else
    skipped "lmto_run_fe_test is false"
  fi

  # Convenience symlinks — only expected when target exists
  section "lmto home symlinks"
  _check_optional_symlink() {
    local label="$1" path="$2" expect="$3"
    if [[ -e "${expect}" || -L "${expect}" ]]; then
      check_symlink "${label}" "${path}" "${expect}"
    else
      if [[ -L "${path}" ]]; then
        ok "${label}: ${path} -> $(readlink "${path}") (target currently missing)"
      else
        skipped "${label}: ${path} (target ${expect} not present — not expected)"
      fi
    fi
  }
  _check_optional_symlink "~/dep24" "${HOME_DIR}/dep24" "/dep24"
  _check_optional_symlink "~/R_dep24" "${HOME_DIR}/R_dep24" "/dep24/dmazur/R"
  _check_optional_symlink "~/TeX_dep24" "${HOME_DIR}/TeX_dep24" "/dep24/dmazur/TeX"

  section "lmto NFS"
  if [[ "$(yaml_bool lmto_nfs_enable)" != "true" ]]; then
    skipped "lmto_nfs_enable is false — NFS mount not expected"
  else
    local nfs_path
    nfs_path="$(yaml_scalar lmto_nfs_path)"
    if findmnt "${nfs_path}" &>/dev/null; then
      ok "NFS mounted at ${nfs_path}"
    else
      missing "NFS not mounted at ${nfs_path}"
    fi
    if grep -qE "${nfs_path}" /etc/fstab 2>/dev/null; then
      ok "fstab has ${nfs_path}"
    else
      missing "fstab missing ${nfs_path}"
    fi
  fi

  section "lmto compiler in environment"
  if [[ -f "${setvars}" ]]; then
    # shellcheck disable=SC1090
    if ( set +u; . "${setvars}" >/dev/null 2>&1; command -v ifx >/dev/null 2>&1 ); then
      local ifx_path
      ifx_path="$(set +u; . "${setvars}" >/dev/null 2>&1; command -v ifx)"
      ok "ifx after setvars: ${ifx_path}"
    else
      missing "ifx not found after sourcing ${setvars}"
    fi
  fi
}

verify_all() {
  printf 'ubuntu-bootstrap install status\n'
  printf 'group_vars: %s\n' "${GROUP_VARS}"
  printf 'home:       %s\n' "${HOME_DIR}"
  # Same order as playbook.yml
  verify_common
  verify_lab
  verify_lmto
  verify_latex
  verify_dotnet
  verify_lmto_ui
  verify_snaps
  verify_claude
  verify_chrome
  verify_debs
  verify_latex_editors
  verify_flatpak
  verify_ollama
  verify_experimental
  print_summary
}
