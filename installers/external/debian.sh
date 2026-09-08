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
    local install_url="https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh"

    info "Installing or updating lazydocker"

    # NOTE:
    # Do not use run_cmd here
    # Dry-run must be checked before the pipeline so curl does not run
    if [[ "${DRY_RUN:-false}" == true ]]; then
        printf '+ curl -fsSL %q | bash\n' "$install_url"
        return 0
    fi

    curl -fsSL "$install_url" | bash
}

install_external_lazygit() {
    local api_url="https://api.github.com/repos/jesseduffield/lazygit/releases/latest"
    local install_dir="/usr/local/bin"

    local version
    local arch
    local tarball_url

    if is_command_available lazygit; then
        info "lazygit already installed"
        return 0
    fi

    info "Installing lazygit"

    arch=$(
        uname -m | sed -e 's/aarch64/arm64/'
    )

    # NOTE:
    # Do not use run_cmd here
    # Dry-run is checked before resolving the latest release so no network lookup runs.
    if [[ "${DRY_RUN:-false}" == true ]]; then
        printf '+ curl -fsSL %q\n' "$api_url"
        printf '+ curl -fsSL -o lazygit.tar.gz %q\n' \
            "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_<VERSION>_Linux_${arch}.tar.gz"
        printf '+ tar xf lazygit.tar.gz lazygit\n'
        printf '+ sudo install lazygit -D -t %q\n' "$install_dir"
        return 0
    fi


    version="$(
        curl -fsSL "$api_url" |
            grep -Po '"tag_name": *"v\K[^"]*'
    )"

    if [[ -z "$version" ]]; then
        echo "Failed to resolve lazygit version." >&2
        return 1
    fi

    tarball_url="https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_${arch}.tar.gz"

    run_cmd curl -fsSL lazygit.tar.gz "$tarball_url"
    run_cmd tar xf lazygit.tar.gz lazygit
    run_cmd sudo install lazygit -D -t /usr/local/bin/
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

install_external_dunst() (
    local version="1.13.2"
    local archive_name="dunst-${version}.tar.gz"
    local download_url="https://github.com/dunst-project/dunst/archive/refs/tags/v${version}.tar.gz"
    local install_path="$HOME/.local/bin/dunst"
    local control_path="$HOME/.local/bin/dunstctl"
    local tmp_dir
    local installed_version
    local missing_dependencies=()
    local dependency
    local dependencies=(
        libdbus-1-dev
        libpango1.0-dev
        libwayland-dev
        libxinerama-dev
        libxrandr-dev
        libxss-dev
        libxdg-basedir-dev
        meson
        ninja-build
        pkg-config
        wayland-protocols
    )

    if [[ -x "$install_path" ]]; then
        installed_version="$("$install_path" --version 2>/dev/null | sed -n 's/.* \([0-9][0-9.]*\).*/\1/p' | head -n 1)"
        if [[ "$installed_version" == "$version" && -x "$control_path" ]]; then
            info "Dunst $version is already installed"
            return 0
        fi
    fi

    info "Installing Dunst $version from upstream"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        run_cmd sudo apt-get install -y "${dependencies[@]}" || return 1
    else
        for dependency in "${dependencies[@]}"; do
            if [[ "$(dpkg-query -W -f='${db:Status-Status}' "$dependency" 2>/dev/null)" != "installed" ]]; then
                missing_dependencies+=("$dependency")
            fi
        done

        if (( ${#missing_dependencies[@]} > 0 )); then
            run_cmd sudo apt-get install -y "${missing_dependencies[@]}" || return 1
        else
            info "Dunst build dependencies are already installed"
        fi
    fi

    tmp_dir="$(mktemp -d)" || return 1
    trap 'rm -rf "$tmp_dir"' EXIT

    run_cmd curl -fL --output "$tmp_dir/$archive_name" "$download_url" || return 1
    run_cmd tar -xzf "$tmp_dir/$archive_name" -C "$tmp_dir" || return 1
    run_cmd meson setup --buildtype=release "$tmp_dir/build" "$tmp_dir/dunst-$version" || return 1
    run_cmd meson compile -C "$tmp_dir/build" || return 1
    run_cmd install -Dm755 "$tmp_dir/build/src/dunst" "$install_path" || return 1
    run_cmd install -Dm755 "$tmp_dir/dunst-$version/dunstctl" "$HOME/.local/bin/dunstctl" || return 1

    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi

    installed_version="$("$install_path" --version 2>/dev/null | sed -n 's/.* \([0-9][0-9.]*\).*/\1/p' | head -n 1)"
    if [[ "$installed_version" != "$version" ]]; then
        error "Failed to install Dunst $version"
        return 1
    fi

    info "Dunst $version installed successfully"
)
