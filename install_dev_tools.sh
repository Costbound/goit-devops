#!/bin/bash

set -e

YELLOW='\033[1;33m'
NC='\033[0m'r

log() { echo -e "${YELLOW}$1${NC}"; }

is_installed() {
    dpkg -s "$1" &>/dev/null
}



# ─── Docker ────────────────────────────────────────────────────────────────────
install_docker() {
    (is_installed docker-ce) && { log "Docker is already installed."; return; }

    # Add Docker's official GPG key:
    is_installed ca-certificates || sudo apt install -y ca-certificates
    is_installed curl || sudo apt install -y curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update 
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    docker_version=$(docker --version 2>/dev/null) || { log "Docker failed to install. Please check the output above for errors."; return 1; }
    log "Docker installed: $docker_version"
}

# ─── Docker Compose ────────────────────────────────────────────────────────────────────

install_docker_compose() {
    (is_installed docker-compose-plugin) && { log "Docker Compose is already installed."; return; }

    sudo apt install -y docker-compose-plugin
    docker_compose_version=$(docker compose version 2>/dev/null) || { log "Docker Compose failed to install. Please check the output above for errors."; return 1; }
    log "Docker Compose installed: $docker_compose_version"
}

# ─── Python 3.9+ ───────────────────────────────────────────────────────────────
install_python() {
    if ! is_installed python3; then
        sudo apt install -y python3
    else
        MAJOR=$(python3 -c 'import sys; print(sys.version_info[0])')
        MINOR=$(python3 -c 'import sys; print(sys.version_info[1])')
        if [ "$MAJOR" -lt 3 ] || [ "$MINOR" -lt 9 ]; then
            sudo apt upgrade -y python3
        fi
    fi
    log "Python installed: $(python3 --version)"
}

# ─── pip ───────────────────────────────────────────────────────────────────────
install_pip() {
    if is_installed python3-pip; then
        log "pip is already installed: $(pip3 --version)"
        return
    fi

    sudo apt install -y python3-pip
    log "pip installed: $(pip3 --version)"
}

# ─── Django ────────────────────────────────────────────────────────────────────
install_django() {
    if python3 -m django --version &>/dev/null 2>&1; then
        log "Django is already installed: $(python3 -m django --version)"
        return
    fi

    pip3 install django --break-system-packages
    log "Django installed: $(python3 -m django --version)"
}

# ─── Main ──────────────────────────────────────────────────────────────────────
main() {
    log "Starting installation of tools on Ubuntu..."
    sudo apt update -y

    install_docker
    install_docker_compose
    install_python
    install_pip
    install_django

    log "All tools installed successfully."
}

main
