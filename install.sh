#!/usr/bin/env bash
# QuorumAI, Bootstrap installer
# Detects OS, installs Python3 + Docker if missing, then runs install.py
set -e

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
step_ok()   { printf "  ${GREEN}✓${NC}  %s\n" "$1"; }
step_fail() { printf "  ${RED}✗${NC}  %s\n" "$1"; exit 1; }
step_info() { printf "  ${YELLOW}→${NC}  %s\n" "$1"; }
step_head() { printf "\n${BOLD}%s${NC}\n" "$1"; }

# Phase 97: Hungarian when the locale is Hungarian, English otherwise.
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
    hu*) HU=1 ;;
    *)   HU=0 ;;
esac
M() { if [ "$HU" = 1 ]; then printf '%s' "$1"; else printf '%s' "$2"; fi; }

trap 'printf "\n${RED}%s${NC} %s\n" "$(M "Hiba a telepítés során." "Installation error.")" "$(M "Nézd meg a fenti hibaüzenetet." "See the error message above.")"' ERR

# ── Header ────────────────────────────────────────────────────────────────────
clear
printf "${BOLD}"
cat << 'EOF'

   ██████╗ ██╗   ██╗ ██████╗ ██████╗ ██╗   ██╗███╗   ███╗ █████╗ ██╗
  ██╔═══██╗██║   ██║██╔═══██╗██╔══██╗██║   ██║████╗ ████║██╔══██╗██║
  ██║   ██║██║   ██║██║   ██║██████╔╝██║   ██║██╔████╔██║███████║██║
  ██║▄▄ ██║██║   ██║██║   ██║██╔══██╗██║   ██║██║╚██╔╝██║██╔══██║██║
  ╚██████╔╝╚██████╔╝╚██████╔╝██║  ██║╚██████╔╝██║ ╚═╝ ██║██║  ██║██║
   ╚══▀▀═╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝

EOF
printf "${NC}"
printf "  %s\n\n" "$(M "Bootstrap telepítő: Python3, Docker, QuorumAI" "Bootstrap installer: Python3, Docker, QuorumAI")"

# Under `curl ... | bash` stdin is the script itself: a `read` would swallow the
# next script line and install.py would fall into headless mode (no license-key
# prompt, no start). So answers are read from the terminal.
TTY=/dev/stdin
if [ ! -t 0 ] && { : < /dev/tty; } 2>/dev/null; then
    TTY=/dev/tty
fi

# ── Root check ────────────────────────────────────────────────────────────────
check_root() {
    if [ "$EUID" -eq 0 ]; then
        printf "  ${YELLOW}⚠${NC}  %s\n" "$(M "Root felhasználóként futtatsz." "You are running as root.")"
        printf "     %s\n" "$(M "A docker csoport hozzáadása root-ra nem ajánlott." "Adding root to the docker group is not recommended.")"
        printf "     %s" "$(M "Nyomj Enter-t a folytatáshoz, vagy Ctrl+C a megszakításhoz: " "Press Enter to continue, or Ctrl+C to abort: ")"
        read -r < "$TTY"
    fi
}

# ── OS Detection ─────────────────────────────────────────────────────────────
detect_os() {
    step_head "[ 1/3 ]  $(M "Operációs rendszer felismerése" "Detecting the operating system")"

    OS=""
    DISTRO=""

    if [ "$(uname -s)" = "Darwin" ]; then
        OS="macos"
        DISTRO="macos"
        step_ok "$(M "macOS felismerve" "macOS detected")"
        return
    fi

    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        DISTRO_ID="${ID:-}"
        DISTRO_ID_LIKE="${ID_LIKE:-}"

        case "$DISTRO_ID" in
            ubuntu)                       OS="debian"; DISTRO="ubuntu" ;;
            debian)                       OS="debian"; DISTRO="debian" ;;
            raspbian)                     OS="debian"; DISTRO="raspbian" ;;
            fedora)                       OS="fedora"; DISTRO="fedora" ;;
            centos|rhel|almalinux|rocky)  OS="rhel";   DISTRO="$DISTRO_ID" ;;
            *)
                # fall back to ID_LIKE
                case "$DISTRO_ID_LIKE" in
                    *debian*|*ubuntu*) OS="debian"; DISTRO="$DISTRO_ID" ;;
                    *fedora*|*rhel*)   OS="rhel";   DISTRO="$DISTRO_ID" ;;
                    *) step_fail "$(M "Nem támogatott Linux disztribúció: $DISTRO_ID. Telepítsd kézzel a Dockert és a Python3-at, majd futtasd: python3 install.py" "Unsupported Linux distribution: $DISTRO_ID. Install Docker and Python3 manually, then run: python3 install.py")" ;;
                esac
                ;;
        esac
        step_ok "Linux / $DISTRO"
    else
        step_fail "$(M "Nem sikerült felismerni az operációs rendszert (/etc/os-release hiányzik)." "Could not detect the operating system (/etc/os-release is missing).")"
    fi
}

# ── Python3 ───────────────────────────────────────────────────────────────────
install_python3() {
    step_head "[ 2/3 ]  Python 3"

    if command -v python3 &>/dev/null; then
        PY_VER=$(python3 --version 2>&1)
        step_ok "$(M "Python3 már telepítve" "Python3 already installed"): $PY_VER"
        return
    fi

    step_info "$(M "Python3 nem található, telepítés..." "Python3 not found, installing...")"

    case "$OS" in
        debian)
            sudo apt-get update -qq
            sudo apt-get install -y python3
            ;;
        fedora)
            sudo dnf install -y python3
            ;;
        rhel)
            sudo yum install -y python3
            ;;
        macos)
            if command -v brew &>/dev/null; then
                brew install python3
            else
                printf "\n"
                printf "  ${YELLOW}%s${NC}\n" "$(M "Python3 nincs telepítve." "Python3 is not installed.")"
                printf "  %s\n" "$(M "Telepítési lehetőségek:" "Install options:")"
                printf "    A) Homebrew: https://brew.sh  ->  brew install python3\n"
                printf "    B) Xcode Command Line Tools: xcode-select --install\n"
                printf "    C) python.org: https://www.python.org/downloads/macos/\n\n"
                printf "  %s\n\n" "$(M "Telepítés után futtasd újra ezt a scriptet." "Run this script again afterwards.")"
                exit 1
            fi
            ;;
    esac

    if command -v python3 &>/dev/null; then
        step_ok "$(M "Python3 telepítve" "Python3 installed"): $(python3 --version 2>&1)"
    else
        step_fail "$(M "Python3 telepítése sikertelen." "Python3 installation failed.")"
    fi
}

# ── Docker ────────────────────────────────────────────────────────────────────
install_docker() {
    step_head "[ 3/3 ]  Docker"

    if command -v docker &>/dev/null; then
        DOCK_VER=$(docker --version 2>&1)
        step_ok "$(M "Docker már telepítve" "Docker already installed"): $DOCK_VER"

        # docker compose plugin check
        if ! docker compose version &>/dev/null; then
            step_info "$(M "docker compose plugin hiányzik, pótlás..." "docker compose plugin missing, installing...")"
            install_docker_engine
        fi
        return
    fi

    step_info "$(M "Docker nem található, telepítés a hivatalos Docker repository-ból..." "Docker not found, installing from the official Docker repository...")"

    case "$OS" in
        debian) install_docker_debian ;;
        fedora) install_docker_fedora ;;
        rhel)   install_docker_rhel   ;;
        macos)  install_docker_macos  ;;
    esac
}

install_docker_debian() {
    # https://docs.docker.com/engine/install/ubuntu/
    # https://docs.docker.com/engine/install/debian/
    # https://docs.docker.com/engine/install/raspberry-pi-os/
    local docker_id="$DISTRO"
    # raspbian → raspberry-pi-os repository neve
    [ "$docker_id" = "raspbian" ] && docker_id="raspbian"

    sudo apt-get update -qq
    sudo apt-get install -y ca-certificates curl

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL "https://download.docker.com/linux/${docker_id}/gpg" \
        -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # shellcheck source=/dev/null
    . /etc/os-release
    local codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/${docker_id} ${codename} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -qq
    sudo apt-get install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    finish_docker_linux
}

install_docker_fedora() {
    # https://docs.docker.com/engine/install/fedora/
    sudo dnf -y install dnf-plugins-core
    sudo dnf-3 config-manager \
        --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null \
        || sudo dnf config-manager \
            --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    finish_docker_linux
}

install_docker_rhel() {
    # https://docs.docker.com/engine/install/centos/
    # https://docs.docker.com/engine/install/rhel/
    sudo yum install -y yum-utils
    sudo yum-config-manager \
        --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    finish_docker_linux
}

finish_docker_linux() {
    sudo systemctl enable --now docker

    if ! id -nG "$USER" | grep -qw docker; then
        sudo usermod -aG docker "$USER"
        # Phase 97: no log-out/log-in round: run_installer continues with `sg docker`.
        step_info "$(M "A docker csoportba felvéve, a telepítő ezzel a csoporttal fut tovább." "Added to the docker group, the installer continues with that group.")"
    fi

    step_ok "$(M "Docker telepítve" "Docker installed"): $(docker --version 2>&1)"
}

install_docker_macos() {
    printf "\n"
    printf "  ${BOLD}Docker Desktop for Mac${NC}\n\n"

    if command -v brew &>/dev/null; then
        step_info "$(M "Telepítés Homebrew-val..." "Installing with Homebrew...")"
        brew install --cask docker
        printf "\n"
        printf "  ${YELLOW}→${NC}  %s\n\n" "$(M "Indítsd el a Docker Desktop alkalmazást, majd futtasd újra ezt a scriptet." "Start the Docker Desktop app, then run this script again.")"
        exit 0
    else
        printf "  %s\n" "$(M "Töltsd le a Docker Desktopot:" "Download Docker Desktop:")"
        printf "  ${BOLD}https://docs.docker.com/desktop/setup/install/mac-install/${NC}\n\n"
        printf "  %s\n\n" "$(M "Telepítés és indítás után futtasd újra ezt a scriptet." "After installing and starting it, run this script again.")"
        printf "  %s" "$(M "Nyomj Enter-t a letöltőoldal megnyitásához, vagy Ctrl+C a kilépéshez: " "Press Enter to open the download page, or Ctrl+C to quit: ")"
        read -r < "$TTY"
        open "https://docs.docker.com/desktop/setup/install/mac-install/" 2>/dev/null || true
        exit 0
    fi
}

# ── macOS: Docker Desktop memory and license warning ─────────────────────────
warn_macos_ram() {
    [ "$OS" = "macos" ] || return 0
    # an update keeps the already bound fingerprint: no warning
    [ -f "${QUORUM_INSTALL_DIR:-$HOME/quorum}/.env" ] && return 0
    printf "\n"
    if [ "$HU" = 1 ]; then
        printf "  ${YELLOW}${BOLD}⚠  FONTOS: Docker Desktop memória és a licenc${NC}\n"
        printf "     A QuorumAI licenc a Docker Desktop virtuális gépéhez kötődik,\n"
        printf "     és az azonosítás része a VM memória-beállítása is.\n\n"
        printf "     Állítsd be ${BOLD}MOST${NC} a végleges értéket:\n"
        printf "     ${BOLD}Docker Desktop > Settings > Resources > Memory${NC}  (ajánlott: legalább 8 GB)\n\n"
        printf "     Ha a telepítés után átméretezed a memóriát, megváltozik a\n"
        printf "     hardver-ujjlenyomat, a licenc érvénytelenné válik, és a\n"
        printf "     supporttól kell új gép-hozzárendelést kérned:\n"
        printf "     https://license.quorumai.eu\n\n"
        printf "     Nyomj Enter-t, ha a memória végleges értékre van állítva: "
    else
        printf "  ${YELLOW}${BOLD}⚠  IMPORTANT: Docker Desktop memory and the license${NC}\n"
        printf "     The QuorumAI license is bound to the Docker Desktop virtual machine,\n"
        printf "     and its memory setting is part of the fingerprint.\n\n"
        printf "     Set the final value ${BOLD}NOW${NC}:\n"
        printf "     ${BOLD}Docker Desktop > Settings > Resources > Memory${NC}  (recommended: at least 8 GB)\n\n"
        printf "     If you resize the memory after installing, the hardware\n"
        printf "     fingerprint changes, the license becomes invalid, and support\n"
        printf "     has to re-assign it to the new machine:\n"
        printf "     https://license.quorumai.eu\n\n"
        printf "     Press Enter once the memory is set to its final value: "
    fi
    read -r < "$TTY"
}

# ── Download and run install.py ──────────────────────────────────────────────
run_installer() {
    step_head "  $(M "QuorumAI telepítő futtatása" "Running the QuorumAI installer")"

    local INSTALL_PY_URL="https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.py"
    local TMP_INSTALLER="/tmp/quorum_install.py"

    step_info "$(M "install.py letöltése..." "Downloading install.py...")"
    if ! curl -fsSL "$INSTALL_PY_URL" -o "$TMP_INSTALLER"; then
        step_fail "$(M "Nem sikerült letölteni az install.py-t. Ellenőrizd az internetkapcsolatot." "Could not download install.py. Check the internet connection.")"
    fi
    step_ok "$(M "Letöltve" "Downloaded"): $TMP_INSTALLER"

    printf "\n"
    # Linux: a docker group membership granted in this session is only active in a
    # new login; `sg docker` gives it to the installer right away.
    if [ "$OS" != "macos" ] && ! docker info >/dev/null 2>&1 \
        && command -v sg >/dev/null 2>&1 && getent group docker | grep -qw "$USER"; then
        sg docker -c "python3 '$TMP_INSTALLER' < '$TTY'"
    else
        python3 "$TMP_INSTALLER" < "$TTY"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    check_root
    detect_os
    install_python3
    install_docker
    warn_macos_ram
    run_installer
}

main "$@"
