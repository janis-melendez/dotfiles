#!/usr/bin/env bash
# Defines Debian-family package installtion logic

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing debian.sh}"

# --- Sources ---
source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/run-command.sh"

# --- APT helpers ---
is_system_package_installed() {
    dpkg -s "$1" &>/dev/null
}

is_repository_configured() {
    local repo="$1"

    if grep -qsF -- "$repo" /etc/apt/sources.list 2>/dev/null ||
        grep -RqsF \
        --include='*.list' \
        --include='*.sources' \
        -- "$repo" /etc/apt/sources.list.d; then
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

# --- Repository Setup ---
setup_gdm_display_manager() {
    if ! is_in_packages_list gdm3 "$@"; then
        return 0
    fi

    info "Selecting GDM as the default display manager"

    run_cmd sudo debconf-set-selections <<'EOF'
gdm3 shared/default-x-display-manager select gdm3
EOF
}

setup_1password_repository() {
    local pkg="1password"
    local repo="1password"

    if ! is_in_packages_list "$pkg" "$@" || is_repository_configured "$repo"; then
        return 0
    fi

    local key_url="https://downloads.1password.com/linux/keys/1password.asc"
    local policy_url="https://downloads.1password.com/linux/debian/debsig/1password.pol"
    local policy_id="AC2D62742012EA22"
    local key_file

    if [[ "${DRY_RUN:-false}" == true ]]; then
        key_file="${TMPDIR:-/tmp}/1password-key.XXXXXX.asc"
    else
        key_file="$(mktemp "${TMPDIR:-/tmp}/1password-key.XXXXXX.asc")"
        trap 'rm -f -- "$key_file"' EXIT
    fi

    info "Configuring $pkg repository"

    run_cmd curl -fsSL \
        "$key_url" \
        -o "$key_file"

    run_cmd sudo install -d -m 0755 \
        /usr/share/keyrings \
        "/etc/debsig/policies/$policy_id" \
        "/usr/share/debsig/keyrings/$policy_id"

    run_cmd sudo gpg --dearmor --yes \
        --output /usr/share/keyrings/1password-archive-keyring.gpg \
        "$key_file"

    run_cmd sudo tee /etc/apt/sources.list.d/1password.list >/dev/null <<EOF
    deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main
EOF

run_cmd sudo curl -fsSL \
    "$policy_url" \
    -o "/etc/debsig/policies/$policy_id/1password.pol"

run_cmd sudo gpg --dearmor --yes \
    --output "/usr/share/debsig/keyrings/$policy_id/debsig.gpg" \
    "$key_file"
}

setup_chrome_repository() {
    local pkg="google-chrome-stable"
    local repo="google-chrome"

    if ! is_in_packages_list "$pkg" "$@" || is_repository_configured "$repo"; then
        return 0
    fi

    info "Configuring Google Chrome repository"

    # Add Google's official GPG key
    run_cmd sudo apt update
    run_cmd sudo apt install -y ca-certificates curl
    run_cmd sudo install -m 0755 -d /etc/apt/keyrings
    run_cmd sudo curl -fsSL \
        https://dl.google.com/linux/linux_signing_key.pub \
        -o /etc/apt/keyrings/google-chrome.asc
    run_cmd sudo chmod a+r /etc/apt/keyrings/google-chrome.asc

    # Add the Google Chrome repository
    run_cmd sudo tee /etc/apt/sources.list.d/google-chrome.sources <<EOF
Types: deb
URIs: https://dl.google.com/linux/chrome/deb/
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/google-chrome.asc
EOF

    run_cmd sudo apt update
}

setup_helium_browser_repository() {
    local pkg="helium-bin"
    local repo="helium"

    if ! is_in_packages_list "$pkg" "$@" || is_repository_configured "$repo"; then
        return 0
    fi

    info "Configuring Helium Browser repository"

    local signing_key="https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        printf '+ curl -fsSL %q | sudo gpg --dearmor -o /usr/share/keyrings/helium.gpg\n' "$signing_key"
        printf '%s\n' '+ echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main" | sudo tee /etc/apt/sources.list.d/helium.list'
        return 0
    fi

    curl -fsSL "$signing_key" | sudo gpg --dearmor -o /usr/share/keyrings/helium.gpg
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main" | sudo tee /etc/apt/sources.list.d/helium.list
}

setup_package_repositories() {
    info "Configuring package repositories"

    setup_gdm_display_manager "$@"
    setup_1password_repository "$@"
    setup_chrome_repository "$@"
    setup_helium_browser_repository "$@"
}

# --- Public entrypoint ---
install_system_packages() {
    local packages=("$@")
    local available_packages=()

    setup_package_repositories "${packages[@]}" ||
        return 1

    info "Installing system packages"

    run_cmd sudo apt-get update ||
        return 1

    for pkg in "${packages[@]}"; do
        if apt-cache show "$pkg" &>/dev/null; then
            available_packages+=("$pkg")
        else
            info "Skipping unavailable package: $pkg"
        fi
    done

    run_cmd sudo apt-get install --install-recommends -y "${available_packages[@]}" ||
        return 1
}
