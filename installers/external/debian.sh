#!/usr/bin/env bash
# Defines Debian-family external tool installs not handled by apt

: "$DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing installers/external/debian.sh"

# --- Sources ---
source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/run-command.sh"

# --- Helper functions ---
is_command_available(){
    command -v "$1" &>/dev/null
}

# --- External tool installers ---
# FIXME: Harden external installs.
# - Avoid curl | bash.
# - Prefer package managers when available and recent enough.
# - Pin release versions instead of installing "latest".
# - For git installs, use pinned tags/commits instead of auto-pulling.
# - For downloaded artifacts, verify checksums when available.

install_external_fzf() {
    install_dir="$HOME/.fzf"

    if is_command_available fzf; then
        info "fzf already installed"
        return 0
    fi

    info "Installing fzf"

    run_cmd git clone --depth 1 https://github.com/junegunn/fzf.git "$install_dir"
    run_cmd "$install_dir/install" --bin
}

install_external_lazydocker() {
    local version="v0.24.0"

    info "Installing lazydocker $version"
    run_cmd go install "github.com/jesseduffield/lazydocker@$version"
}

install_external_lazygit() {
    info "Installing or updating lazygit"
    run_cmd go install github.com/jesseduffield/lazygit@latest
}

install_external_neovim() {
    # TODO: Pin Neovim to a specific version to avoid unexpected config breakage.
    # local pinned_version="0.12.2"

    local tarball_name="nvim-linux-x86_64.tar.gz"
    local tarball_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    local tarball_dir="/opt/nvim-linux-x86_64"

    if is_command_available nvim; then
        info "nvim already installed"
        return 0
    fi

    info "Installing nvim"

    run_cmd curl -fSLO "$tarball_url"
    run_cmd sudo rm -rf "$tarball_dir"
    run_cmd sudo tar -C /opt -xzf "$tarball_name"
    run_cmd sudo ln -sf "$tarball_dir/bin/nvim" /usr/local/bin/nvim
}

install_external_resvg() {
    if is_command_available resvg; then
        info "resvg already installed"
        return 0
    fi

    if ! is_command_available cargo; then
        info "Cargo is required to install resvg"
        return 0
    fi

    info "Installing resvg"
    run_cmd cargo install resvg --locked
}

install_external_proton_mail() (
    info "Installing Proton Mail"

    local download_url='https://proton.me/download/mail/linux/ProtonMail-desktop-beta.deb'
    local temp_dir
    local package_path

    temp_dir="$(mktemp -d)"
    package_path="$temp_dir/ProtonMail-desktop-beta.deb"

    trap 'rm -rf "$temp_dir"' EXIT

    run_cmd curl -fL \
        --output "$package_path" \
        "$download_url"

    run_cmd sudo apt install -y "$package_path"
)

install_external_proton_pass() (
    info "Installing Proton Pass"

    local download_url='https://proton.me/download/PassDesktop/linux/x64/ProtonPass.deb'
    local temp_dir
    local package_path

    temp_dir="$(mktemp -d)"
    package_path="$temp_dir/ProtonPass.deb"

    trap 'rm -rf "$temp_dir"' EXIT

    run_cmd curl -fL \
        --output "$package_path" \
        "$download_url"

    run_cmd sudo apt install -y "$package_path"
)

install_external_zoxide() {
    local install_url="https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"

    if is_command_available zoxide; then
        info "zoxide already installed"
        return 0
    fi

    info "Installing zoxide"

    # NOTE:
    # Do not use run_cmd here
    # Dry-run must be checked before the pipeline so curl does not run
    if [[ "${DRY_RUN:-false}" == true ]]; then
        printf '+ curl -fsSL %q | sh\n' "$install_url"
        return 0
    fi

    curl -fsSL "$install_url" | sh
}
