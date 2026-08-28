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

trap 'printf "\n${RED}Hiba a telepítés során.${NC} Nézd meg a fenti hibaüzenetet.\n"' ERR

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
printf "  %s\n\n" "Bootstrap telepítő, Python3, Docker, QuorumAI"

# ── Root check ────────────────────────────────────────────────────────────────
check_root() {
    if [ "$EUID" -eq 0 ]; then
        printf "  ${YELLOW}⚠${NC}  Root felhasználóként futtatsz.\n"
        printf "     A docker csoport hozzáadása root-ra nem ajánlott.\n"
        printf "     Nyomj Enter-t a folytatáshoz, vagy Ctrl+C a megszakításhoz: "
        read -r
    fi
}

# ── OS Detection ─────────────────────────────────────────────────────────────
detect_os() {
    step_head "[ 1/3 ]  Operációs rendszer felismerése"

    OS=""
    DISTRO=""

    if [ "$(uname -s)" = "Darwin" ]; then
        OS="macos"
        DISTRO="macos"
        step_ok "macOS felismerve"
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
                # Próbálj ID_LIKE alapján dönteni
                case "$DISTRO_ID_LIKE" in
                    *debian*|*ubuntu*) OS="debian"; DISTRO="$DISTRO_ID" ;;
                    *fedora*|*rhel*)   OS="rhel";   DISTRO="$DISTRO_ID" ;;
                    *) step_fail "Nem támogatott Linux disztribúció: $DISTRO_ID. Telepítsd kézzel a Dockert és a Python3-at, majd futtasd: python3 install.py" ;;
                esac
                ;;
        esac
        step_ok "Linux / $DISTRO"
    else
        step_fail "Nem sikerült felismerni az operációs rendszert (/etc/os-release hiányzik)."
    fi
}

# ── Python3 ───────────────────────────────────────────────────────────────────
install_python3() {
    step_head "[ 2/3 ]  Python 3"

    if command -v python3 &>/dev/null; then
        PY_VER=$(python3 --version 2>&1)
        step_ok "Python3 már telepítve: $PY_VER"
        return
    fi

    step_info "Python3 nem található, telepítés..."

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
                printf "  ${YELLOW}Python3 nincs telepítve.${NC}\n"
                printf "  Telepítési lehetőségek:\n"
                printf "    A) Homebrew (ajánlott): https://brew.sh  →  brew install python3\n"
                printf "    B) Xcode Command Line Tools: xcode-select --install\n"
                printf "    C) python.org: https://www.python.org/downloads/macos/\n\n"
                printf "  Telepítés után futtasd újra ezt a scriptet.\n\n"
                exit 1
            fi
            ;;
    esac

    if command -v python3 &>/dev/null; then
        step_ok "Python3 telepítve: $(python3 --version 2>&1)"
    else
        step_fail "Python3 telepítése sikertelen."
    fi
}

# ── Docker ────────────────────────────────────────────────────────────────────
install_docker() {
    step_head "[ 3/3 ]  Docker"

    if command -v docker &>/dev/null; then
        DOCK_VER=$(docker --version 2>&1)
        step_ok "Docker már telepítve: $DOCK_VER"

        # docker compose plugin ellenőrzés
        if ! docker compose version &>/dev/null; then
            step_info "docker compose plugin hiányzik, pótlás..."
            install_docker_engine
        fi
        return
    fi

    step_info "Docker nem található, telepítés a hivatalos Docker repository-ból..."

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

    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
        printf "\n"
        printf "  ${YELLOW}⚠  FONTOS:${NC} A docker csoport aktiválásához\n"
        printf "     ${BOLD}jelentkezz ki és be újra${NC}, majd futtasd újra a scriptet:\n\n"
        printf "     ${BOLD}curl -fsSL https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.sh | bash${NC}\n\n"
        exit 0
    fi

    step_ok "Docker telepítve: $(docker --version 2>&1)"
}

install_docker_macos() {
    printf "\n"
    printf "  ${BOLD}Docker Desktop for Mac${NC}\n\n"

    if command -v brew &>/dev/null; then
        step_info "Homebrew segítségével telepítés..."
        brew install --cask docker
        printf "\n"
        printf "  ${YELLOW}→${NC}  Indítsd el a Docker Desktop alkalmazást,\n"
        printf "     majd futtasd újra ezt a scriptet a telepítés folytatásához.\n\n"
        exit 0
    else
        printf "  Töltsd le a Docker Desktop-ot:\n"
        printf "  ${BOLD}https://docs.docker.com/desktop/setup/install/mac-install/${NC}\n\n"
        printf "  Telepítés és indítás után futtasd újra ezt a scriptet.\n\n"
        printf "  Nyomj Enter-t a megnyitáshoz (ha van 'open' parancs), vagy Ctrl+C a kilépéshez: "
        read -r
        open "https://docs.docker.com/desktop/setup/install/mac-install/" 2>/dev/null || true
        exit 0
    fi
}

# ── macOS: Docker Desktop RAM + licenc figyelmeztetés ────────────────────────
warn_macos_ram() {
    [ "$OS" = "macos" ] || return 0
    printf "\n"
    printf "  ${YELLOW}${BOLD}⚠  FONTOS, Docker Desktop memória és a licenc${NC}\n"
    printf "     A QuorumAI licenc a Docker Desktop virtuális gépéhez kötődik,\n"
    printf "     és az azonosítás része a VM memória-beállítása is.\n\n"
    printf "     Állítsd be ${BOLD}MOST${NC} a végleges értéket:\n"
    printf "     ${BOLD}Docker Desktop → Settings → Resources → Memory${NC}  (ajánlott: legalább 8 GB)\n\n"
    printf "     Ha a telepítés után átméretezed a memóriát, megváltozik a\n"
    printf "     hardver-ujjlenyomat, a licenc érvénytelenné válik, és a\n"
    printf "     supporttól kell új gép-hozzárendelést kérned:\n"
    printf "     https://license.quorumai.eu\n\n"
    printf "     Nyomj Enter-t, ha a memória végleges értékre van állítva: "
    read -r
}

# ── install.py letöltés és futtatás ──────────────────────────────────────────
run_installer() {
    step_head "  QuorumAI telepítő futtatása"

    local INSTALL_PY_URL="https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.py"
    local TMP_INSTALLER="/tmp/quorum_install.py"

    step_info "install.py letöltése..."
    if ! curl -fsSL "$INSTALL_PY_URL" -o "$TMP_INSTALLER"; then
        step_fail "Nem sikerült letölteni az install.py-t. Ellenőrizd az internetkapcsolatot."
    fi
    step_ok "Letöltve: $TMP_INSTALLER"

    printf "\n"
    python3 "$TMP_INSTALLER"
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
