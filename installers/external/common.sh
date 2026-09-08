#!/usr/bin/env bash
# Defines shared external tool installers

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing installers/external/common.sh}"

source "$DOTFILES_DIR/lib/install-or-update-repo.sh"
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

font_is_installed() {
    local font_family="$1"

    [[ -n "$font_family" ]] || return 1

    fc-list --format='%{family}\n' |
        awk -F ',' -v target="$font_family" '
            BEGIN {
                target = tolower(target)
            }

            {
                for (i = 1; i <= NF; i++) {
                    family = $i
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", family)

                    if (tolower(family) == target) {
                        found = 1
                    }
                }
            }

            END {
                exit !found
            }
        '
}

install_external_font() (
    local file_name="$1"
    local install_dir="$2"
    local font_family="$3"
    local download_url="$4"

    local fonts_folder="$HOME/.local/share/fonts"
    local install_folder="$fonts_folder/$install_dir"

    if font_is_installed "$font_family"; then
        info "$font_family is already installed"
        return 0
    fi

    info "Installing $font_family font"

    # Setup temp download directory
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT

    local download_path="$tmp_dir/$file_name"

    run_cmd mkdir -p "$install_folder" || return 1

    # Download and extract
    if ! run_cmd wget -O "$download_path" "$download_url"; then
        error "Failed to download $font_family"
        return 1
    fi

    if ! run_cmd 7z x -y "$download_path" "-o$install_folder"; then
        error "Failed to extract $font_family"
        return 1
    fi

    # Rebuild font cache
    run_cmd fc-cache -fv || return 1

    # Commands are intentionally skipped during dry runs
    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi

    # Verify Install
    if font_is_installed "$font_family"; then
        info "$font_family installed successfully"
        return 0
    fi

    error "Failed to install $font_family"
    return 1
)

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

install_external_autotiling() {
    if [[ "$OS" == "macos" ]]; then
        info "Skipping external autotiling install"
        return 0
    fi

    info "Installing autotiling script (i3 and sway dependency)"

    if [[ "$OS" == "debian" ]]; then
        run_cmd pipx install autotiling
        return 0
    fi

    run_cmd pip install autotiling
}

install_external_bibata_cursor_theme() (
    local version="$EXTERNAL_VERSION_BIBATA_CURSOR"
    local theme_name="Bibata-Modern-Ice"
    local archive_name="$theme_name.tar.xz"
    local download_url="https://github.com/ful1e5/Bibata_Cursor/releases/download/$version/$archive_name"

    local icons_dir="$HOME/.local/share/icons"
    local install_dir="$icons_dir/$theme_name"

    if [[ -f "$install_dir/index.theme" &&
          -e "$install_dir/cursors/left_ptr" ]]; then
        info "$theme_name cursor theme is already installed"
        return 0
    fi

    info "Installing $theme_name cursor theme"

    local tmp_dir
    tmp_dir="$(mktemp -d)" || return 1
    trap 'rm -rf "$tmp_dir"' EXIT

    local download_path="$tmp_dir/$archive_name"

    run_cmd mkdir -p "$icons_dir" || return 1

    run_cmd wget -O "$download_path" "$download_url" || return 1

    run_cmd tar -xJf "$download_path" -C "$icons_dir" || return 1

    info "$theme_name cursor theme installed successfully"
)

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

install_external_dejadup() {
    info "Installing DejaDup"
    run_cmd flatpak install --noninteractive --assumeyes flathub org.gnome.DejaDup
}


install_external_dejavu_font() {
    local file_name="dejavu-fonts-ttf-2.37.zip"
    local install_dir="DejaVu"
    local font_family="DejaVu Sans"
    local download_url="https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.zip"

    install_external_font \
        "$file_name" \
        "$install_dir" \
        "$font_family" \
        "$download_url"
}

install_external_fira_code_font() {
    local version="$EXTERNAL_VERSION_FIRA_CODE"
    local file_name="FiraCode.zip"
    local install_dir="FiraCodeNerdFont"
    local font_family="FiraCode Nerd Font"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/$version/$file_name"

    install_external_font \
        "$file_name" \
        "$install_dir" \
        "$font_family" \
        "$download_url"
}

install_external_graphite_theme() (
    local gtk_repo_url="https://github.com/vinceliuice/Graphite-gtk-theme.git"
    local kde_repo_url="https://github.com/vinceliuice/Graphite-kde-theme.git"
    local gtk_version="$EXTERNAL_VERSION_GRAPHITE_GTK"
    local kde_version="$EXTERNAL_VERSION_GRAPHITE_KDE"

    local gtk_theme_dir="$HOME/.themes/Graphite-Dark-nord"
    local kvantum_theme_dir="$HOME/.config/Kvantum/GraphiteNord"

    if [[ -f "$gtk_theme_dir/gtk-3.0/gtk.css" &&
          -f "$gtk_theme_dir/gtk-4.0/gtk.css" &&
          -f "$kvantum_theme_dir/GraphiteNord.kvconfig" &&
          -f "$kvantum_theme_dir/GraphiteNordDark.kvconfig" ]]; then
        info "Graphite Nord theme is already installed"
        return 0
    fi

    info "Installing Graphite Nord theme"

    local tmp_dir
    tmp_dir="$(mktemp -d)" || return 1
    trap 'rm -rf -- "$tmp_dir"' EXIT

    local gtk_source_dir="$tmp_dir/Graphite-gtk-theme"
    local kde_source_dir="$tmp_dir/Graphite-kde-theme"

    run_cmd git clone --depth 1 --branch "$gtk_version" \
        "$gtk_repo_url" \
        "$gtk_source_dir" ||
        return 1

    run_cmd git clone --depth 1 --branch "$kde_version" \
        "$kde_repo_url" \
        "$kde_source_dir" ||
        return 1

    # GTK
    run_cmd bash "$gtk_source_dir/install.sh" \
        -d "$HOME/.themes" \
        -c dark \
        --tweaks nord normal ||
        return 1

    # Qt / Kvantum
    run_cmd mkdir -p "$kvantum_theme_dir" ||
        return 1

    run_cmd cp -a \
        "$kde_source_dir/Kvantum/GraphiteNord/." \
        "$kvantum_theme_dir/" ||
        return 1

    # Sets GraphiteNord as the default kvantum-dark theme
    # run_cmd kvantummanager --set GraphiteNord ||
        # return 1

    info "Graphite Nord theme installed successfully"
)

install_external_hack_font() {
    local version="$EXTERNAL_VERSION_HACK_FONT"
    local file_name="Hack.zip"
    local install_dir="HackNerdFont"
    local font_family="Hack Nerd Font Mono"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/$version/$file_name"

    install_external_font \
        "$file_name" \
        "$install_dir" \
        "$font_family" \
        "$download_url"
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

install_external_julia_mono_font() {
    local version="$EXTERNAL_VERSION_JULIA_MONO"
    local file_name="JuliaMono.zip"
    local install_dir="JuliaMono"
    local font_family="JuliaMono"
    local download_url="https://github.com/cormullion/juliamono/releases/download/$version/$file_name"

    install_external_font \
        "$file_name" \
        "$install_dir" \
        "$font_family" \
        "$download_url"
}

install_external_nordic_theme() (
    local repo_url="https://github.com/EliverLara/Nordic.git"
    local version="$EXTERNAL_VERSION_NORDIC"

    local gtk_theme_dir="$HOME/.themes/Nordic"
    local kvantum_theme_dir="$HOME/.config/Kvantum/Nordic"

    if [[ -f "$gtk_theme_dir/index.theme" &&
          -f "$gtk_theme_dir/gtk-3.0/gtk.css" &&
          -f "$gtk_theme_dir/gtk-4.0/gtk.css" &&
          -f "$kvantum_theme_dir/Nordic.kvconfig" &&
          -f "$kvantum_theme_dir/Nordic.svg" ]]; then
        info "Nordic theme is already installed"
        return 0
    fi

    info "Installing Nordic theme"

    local tmp_dir
    tmp_dir="$(mktemp -d)" || return 1
    trap 'rm -rf "$tmp_dir"' EXIT

    local source_dir="$tmp_dir/Nordic"

    run_cmd git clone --depth 1 --branch "$version" "$repo_url" "$source_dir" ||
        return 1

    run_cmd mkdir -p "$gtk_theme_dir" "$kvantum_theme_dir" ||
        return 1

    local gtk_paths=(
        assets
        cinnamon
        gnome-shell
        gtk-2.0
        gtk-3.0
        gtk-4.0
        metacity-1
        xfwm4
        index.theme
    )

    for path in "${gtk_paths[@]}"; do
        run_cmd cp -a "$source_dir/$path" "$gtk_theme_dir/" ||
            return 1
    done

    run_cmd cp -a \
        "$source_dir/kde/kvantum/Nordic/." \
        "$kvantum_theme_dir/" ||
        return 1

    # Sets Nordic as the default kvantum-dark theme
    run_cmd kvantummanager --set Nordic ||
        return 1

    info "Nordic theme installed successfully"
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

    info "Installing Yazi"
    run_cmd cargo install --force yazi-build --version "$EXTERNAL_VERSION_YAZI"
}

# TODO: create a install_cargo function
install_external_workmux() {
    if ! command -v cargo; then
        warn "Cargo is required to install workmux"
        return 1
    fi

    if command -v workmux; then
        warn "workmux already installed"
        return 0
    fi

    info "Installing Workmux"
    run_cmd cargo install workmux --version "$EXTERNAL_VERSION_WORKMUX"
}

install_external_zen_browser() {
    info "Installing Zen Browser"
    run_cmd flatpak install --noninteractive --assumeyes flathub app.zen_browser.zen
}
