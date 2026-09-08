#!/usr/bin/env bash
# Defines Fedora-family package installation logic

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing installers/fedora.sh}"

# --- Sources ---
source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/run-command.sh"

# --- Fedora package helpers ---
is_system_package_installed() {
    rpm -q "$1" &>/dev/null
}

is_repository_configured() {
    local repo="$1"
    local repos_dir="/etc/yum.repos.d"

    if grep -RqsF \
        --include='*.repo' \
        -- "$repo" "$repos_dir"; then
        info "$repo repository is already configured"
        return 0
    fi

    return 1
}

is_in_packages_list() {
    local target_package="$1"
    shift

    local packages_list=("$@")

    for pkg in "${packages_list[@]}"; do
        if [[ "$pkg" = "$target_package" ]]; then
            return 0
        fi
    done

    info "Skipping $target_package repository setup"
    return 1
}

# --- repository setup ---
setup_1password_repository() {
    local pkg="1password"
    local repo="1password"

    if ! is_in_packages_list "$pkg" "$@" || is_repository_configured "$pkg"; then
        return 0
    fi

    info "configuring $pkg repository"

    run_cmd sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
    run_cmd sudo sh -c 'echo -e "[1password]\nname=1password stable channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
}

setup_chrome_repository() {
    local pkg="google-chrome-stable"
    local repo="google-chrome"

    if ! is_in_packages_list "$pkg" "$@" || is_repository_configured "$repo"; then
        return 0
    fi

    info "Configuring Google Chrome repository"

    # Add Google's official signing key
    run_cmd sudo rpm --import \
        https://dl.google.com/linux/linux_signing_key.pub

    # Add the Google Chrome repository
    run_cmd sudo tee /etc/yum.repos.d/google-chrome.repo <<EOF
[google-chrome]
name=Google Chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

    run_cmd sudo dnf makecache
}

setup_dms_repository() {
    local pkg="dms"
    local repo="dms"

    if ! is_in_packages_list "$pkg" "$@" || is_repository_configured "$repo"; then
        return 0
    fi

    info "Configuring $pkg repository"

    run_cmd sudo dnf copr enable -y avengemedia/dms
}

setup_helium_browser_repository() {
    local pkg="helium-bin"
    local repo="helium"

    if ! is_in_packages_list "$pkg" "$@" || is_repository_configured "$repo"; then
        return 0
    fi

    info "configuring $pkg repository"

    run_cmd sudo dnf copr enable -y imput/helium
}

setup_ghostty_repository() {
    local pkg="ghostty"
    local repo="ghostty"

    if ! is_in_packages_list "$pkg" "$@" || is_repository_configured "$repo"; then
        return 0
    fi

    info "configuring $pkg repository"

    run_cmd sudo dnf copr enable -y scottames/ghostty
}

setup_swayfx_repository() {
    local pkg="swayfx"
    local repo="swayfx"

    if ! is_in_packages_list "$pkg" "$@" || is_repository_configured "$repo"; then
        return 0
    fi

    info "Configuring $pkg repository"

    run_cmd sudo dnf copr enable -y swayfx/swayfx
}

setup_package_repositories() {
    info "Configuring package repositories"

    setup_1password_repository "$@"
    setup_chrome_repository "$@"
    setup_dms_repository "$@"
    setup_ghostty_repository "$@"
    setup_helium_browser_repository "$@"
    setup_swayfx_repository "$@"
}

# --- public entrypoint ---
install_system_packages() {
    local packages=("$@")

    setup_package_repositories "${packages[@]}"

    info "installing system packages"
    run_cmd sudo dnf install -y "${packages[@]}"
}
