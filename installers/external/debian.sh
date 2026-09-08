#!/usr/bin/env bash
# Defines Debian-family external tool installs not handled by apt

: "$DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing installers/external/debian.sh"

# --- Sources ---
source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/run-command.sh"
source "$DOTFILES_DIR/installers/external/versions.sh"

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
    local version="$EXTERNAL_VERSION_FZF"
    local install_dir="$HOME/.fzf"

    if is_command_available fzf; then
        info "fzf already installed"
        return 0
    fi

    info "Installing fzf $version"

    run_cmd git clone --depth 1 --branch "$version" \
        https://github.com/junegunn/fzf.git "$install_dir"
    run_cmd "$install_dir/install" --bin
}

install_external_lazydocker() {
    local version="$EXTERNAL_VERSION_LAZYDOCKER"

    info "Installing lazydocker $version"
    run_cmd go install "github.com/jesseduffield/lazydocker@$version"
}

install_external_lazygit() {
    info "Installing lazygit $EXTERNAL_VERSION_LAZYGIT"
    run_cmd go install "github.com/jesseduffield/lazygit@$EXTERNAL_VERSION_LAZYGIT"
}

install_external_neovim() {
    local version="$EXTERNAL_VERSION_NEOVIM"
    local tarball_name="nvim-linux-x86_64.tar.gz"
    local tarball_url="https://github.com/neovim/neovim/releases/download/$version/$tarball_name"
    local tarball_dir="/opt/nvim-linux-x86_64"

    if is_command_available nvim; then
        info "nvim already installed"
        return 0
    fi

    info "Installing nvim $version"

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

    info "Installing resvg $EXTERNAL_VERSION_RESVG"
    run_cmd cargo install resvg --version "$EXTERNAL_VERSION_RESVG" --locked
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

install_external_zoxide() (
    local version="$EXTERNAL_VERSION_ZOXIDE"
    local target
    local archive
    local download_url
    local checksum
    local temp_dir

    if is_command_available zoxide; then
        info "zoxide already installed"
        return 0
    fi

    case "$(uname -m)" in
        x86_64) target="x86_64-unknown-linux-musl"; checksum="$EXTERNAL_SHA256_ZOXIDE_LINUX_X86_64" ;;
        aarch64|arm64) target="aarch64-unknown-linux-musl"; checksum="$EXTERNAL_SHA256_ZOXIDE_LINUX_AARCH64" ;;
        *) error "Unsupported architecture for zoxide: $(uname -m)"; return 1 ;;
    esac

    archive="zoxide-$version-$target.tar.gz"
    download_url="https://github.com/ajeetdsouza/zoxide/releases/download/v$version/$archive"

    info "Installing zoxide $version"

    # NOTE:
    # Do not use run_cmd here
    # Dry-run must be checked before the pipeline so curl does not run
    if [[ "${DRY_RUN:-false}" == true ]]; then
        printf '+ curl -fL --output %q %q\n' "$archive" "$download_url"
        printf '+ verify_sha256 %q %q\n' "$archive" "$checksum"
        return 0
    fi

    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' EXIT
    run_cmd curl -fL --output "$temp_dir/$archive" "$download_url" || return 1
    verify_sha256 "$temp_dir/$archive" "$checksum" || return 1
    run_cmd tar -xzf "$temp_dir/$archive" -C "$temp_dir" --strip-components=1 || return 1
    run_cmd mkdir -p "$HOME/.local/bin" || return 1
    run_cmd install -m755 "$temp_dir/zoxide" "$HOME/.local/bin/zoxide"
)
