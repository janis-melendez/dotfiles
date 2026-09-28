#!/usr/bin/env bash
# Defines shared external tool installers

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing installers/external/common.sh}"

source "$DOTFILES_DIR/lib/install-or-update-repo.sh"
source "$DOTFILES_DIR/lib/install-cargo-package.sh"
source "$DOTFILES_DIR/installers/external/versions.sh"

# --- Helpers ---
verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual

    if command -v sha256sum >/dev/null 2>&1; then
        actual="$(sha256sum "$file" | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
        actual="$(shasum -a 256 "$file" | awk '{print $1}')"
    else
        error "A SHA-256 tool is required to verify $file"
        return 1
    fi

    if [[ "$actual" != "$expected" ]]; then
        error "Checksum verification failed: $file"
        return 1
    fi
}

# --- External functions ---

# Manages zsh-plugins
install_external_antidote() {
    install_or_update_repo \
        "https://github.com/mattmc3/antidote.git" \
        "${ZDOTDIR:-$HOME}/.antidote"
}

# Manual alternative to Antidote.
# To switch back, add "zsh_plugins" to the relevant EXTERNAL_CORE arrays
# and update .zshrc to source these plugins instead of loading Antidote.
# The cloned repos can coexist, but .zshrc should only load one set.
install_external_zsh_plugins() {
    local zsh_plugins_dir="$HOME/.zsh/plugins"

    info "Installing zsh plugins"

    run_cmd mkdir -p "$zsh_plugins_dir"

    install_or_update_repo \
        "https://github.com/zsh-users/zsh-autosuggestions" \
        "$zsh_plugins_dir/zsh-autosuggestions"

    install_or_update_repo \
        "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
        "$zsh_plugins_dir/zsh-syntax-highlighting"

    install_or_update_repo \
        "https://github.com/Aloxaf/fzf-tab" \
        "$zsh_plugins_dir/fzf-tab"

    install_or_update_repo \
        "https://github.com/zsh-users/zsh-completions" \
        "$zsh_plugins_dir/zsh-completions"

    install_or_update_repo \
        "https://github.com/zsh-users/zsh-history-substring-search.git" \
        "$zsh_plugins_dir/zsh-history-substring-search"
}

install_external_bun() {
    local version="$EXTERNAL_VERSION_BUN"
    local install_url="https://bun.sh/install"

    if command -v bun >/dev/null 2>&1; then
        info "Bun is already installed"
        return 0
    fi

    info "Installing Bun"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        printf '+ curl -fsSL %q | bash -s -- %q\n' "$install_url" "$version"
        return 0
    fi

    curl -fsSL "$install_url" | bash -s -- "$version"
}

install_external_claude_code() {
    local version="$EXTERNAL_VERSION_CLAUDE_CODE"
    if command -v claude &>/dev/null; then
        info "Claude Code is already installed"
        return 0
    fi

    info "Installing Claude Code"

    if [[ "${DRY_RUN:-false}" = true ]]; then
        printf '+ curl -fsSL https://claude.ai/install.sh | bash -s -- %q\n' "$version"
        return 0
    fi

    curl -fsSL https://claude.ai/install.sh | bash -s -- "$version"
}

install_external_codex() {
    local version="$EXTERNAL_VERSION_CODEX"
    if command -v codex &>/dev/null; then
        info "Codex is already installed"
        return 0
    fi

    info "Installing Codex"

    if [[ "${DRY_RUN:-false}" = true ]]; then
        printf '+ curl -fsSL https://chatgpt.com/codex/install.sh | sh -s -- --release %q\n' "$version"
        return 0
    fi

    curl -fsSL https://chatgpt.com/codex/install.sh | sh -s -- --release "$version"
}

install_external_herdr() (
    local version="$EXTERNAL_VERSION_HERDR"
    local target
    local download_url
    local checksum
    local temp_dir

    if command -v herdr >/dev/null 2>&1; then
        info "Herdr is already installed"
        return 0
    fi

    case "$(uname -s)-$(uname -m)" in
        Linux-x86_64) target="linux-x86_64"; checksum="$EXTERNAL_SHA256_HERDR_LINUX_X86_64" ;;
        Linux-aarch64) target="linux-aarch64"; checksum="$EXTERNAL_SHA256_HERDR_LINUX_AARCH64" ;;
        Darwin-x86_64) target="macos-x86_64"; checksum="$EXTERNAL_SHA256_HERDR_MACOS_X86_64" ;;
        Darwin-arm64) target="macos-aarch64"; checksum="$EXTERNAL_SHA256_HERDR_MACOS_AARCH64" ;;
        *) error "Unsupported platform for Herdr"; return 1 ;;
    esac

    download_url="https://github.com/herdrdev/herdr/releases/download/v$version/herdr-$target"
    info "Installing Herdr $version"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        printf '+ curl -fL --output %q %q\n' "<temporary Herdr binary>" "$download_url"
        printf '+ verify_sha256 %q %q\n' "<temporary Herdr binary>" "$checksum"
        return 0
    fi

    temp_dir="$(mktemp -d)" || return 1
    trap 'rm -rf "$temp_dir"' EXIT
    run_cmd mkdir -p "$HOME/.local/bin" || return 1
    run_cmd curl -fL --output "$temp_dir/herdr" "$download_url" || return 1
    verify_sha256 "$temp_dir/herdr" "$checksum" || return 1
    run_cmd install -m755 "$temp_dir/herdr" "$HOME/.local/bin/herdr"
)

install_external_oh_my_posh() {
    local version="$EXTERNAL_VERSION_OH_MY_POSH"
    local install_url="https://ohmyposh.dev/install.sh"

    if is_command_available oh-my-posh; then
        info "oh-my-posh already installed"
        return 0
    fi

    info "Installing oh-my-posh"

    # NOTE:
    # Do not wrap this in run_cmd.
    # Dry run must be checked before the pipeline so curl does not run
    if [[ "${DRY_RUN:-false}" == true ]]; then
        printf '+ curl -fsSL %q | bash -s -- -v %q\n' "$install_url" "$version"
        return 0
    fi

    printf '+ curl -fsSL %q | bash -s -- -v %q\n' "$install_url" "$version"
    curl -fsSL "$install_url" | bash -s -- -v "$version"
}

install_external_yazi() {
    if ! command -v cargo; then
        warn "Cargo is required to install Yazi"
        return 1
    fi

    if command -v yazi; then
        info "Yazi already installed"
        return
    fi

    install_cargo_package yazi-build "$EXTERNAL_VERSION_YAZI" --force
}

install_external_workmux() {
    if ! command -v cargo; then
        warn "Cargo is required to install workmux"
        return 1
    fi

    if command -v workmux; then
        warn "workmux already installed"
        return 0
    fi

    install_cargo_package workmux "$EXTERNAL_VERSION_WORKMUX"
}
