#!/usr/bin/env bash
# Defines shared Linux external tool installers

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing installers/external/common-linux.sh}"

source "$DOTFILES_DIR/lib/install-flathub-package.sh"

# --- Helpers ---
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

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT

    local download_path="$tmp_dir/$file_name"

    run_cmd mkdir -p "$install_folder" || return 1

    if ! run_cmd wget -O "$download_path" "$download_url"; then
        error "Failed to download $font_family"
        return 1
    fi

    if ! run_cmd 7z x -y "$download_path" "-o$install_folder"; then
        error "Failed to extract $font_family"
        return 1
    fi

    run_cmd fc-cache -fv || return 1

    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi

    if font_is_installed "$font_family"; then
        info "$font_family installed successfully"
        return 0
    fi

    error "Failed to install $font_family"
    return 1
)

# --- External functions ---
install_external_autotiling() {
    info "Installing autotiling script (i3 and sway dependency)"

    if [[ "$OS" == "debian" ]]; then
        run_cmd pipx install autotiling
        return 0
    fi

    run_cmd pip install autotiling
}

install_external_brave() {
    install_flathub_package com.brave.Browser
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

install_external_dejadup() {
    install_flathub_package org.gnome.DejaDup
}

install_external_dejavu_font() {
    local file_name="dejavu-fonts-ttf-2.37.zip"
    local install_dir="DejaVu"
    local font_family="DejaVu Sans"
    local download_url="https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.zip"

    install_external_font "$file_name" "$install_dir" "$font_family" "$download_url"
}

install_external_fira_code_font() {
    local version="$EXTERNAL_VERSION_FIRA_CODE"
    local file_name="FiraCode.zip"
    local install_dir="FiraCodeNerdFont"
    local font_family="FiraCode Nerd Font"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/$version/$file_name"

    install_external_font "$file_name" "$install_dir" "$font_family" "$download_url"
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
        "$gtk_repo_url" "$gtk_source_dir" || return 1
    run_cmd git clone --depth 1 --branch "$kde_version" \
        "$kde_repo_url" "$kde_source_dir" || return 1

    run_cmd bash "$gtk_source_dir/install.sh" \
        -d "$HOME/.themes" -c dark --tweaks nord normal || return 1

    run_cmd mkdir -p "$kvantum_theme_dir" || return 1
    run_cmd cp -a "$kde_source_dir/Kvantum/GraphiteNord/." \
        "$kvantum_theme_dir/" || return 1

    # Sets GraphiteNord as the default kvantum-dark theme
    # run_cmd kvantummanager --set GraphiteNord || return 1

    info "Graphite Nord theme installed successfully"
)

install_external_hack_font() {
    local version="$EXTERNAL_VERSION_HACK_FONT"
    local file_name="Hack.zip"
    local install_dir="HackNerdFont"
    local font_family="Hack Nerd Font Mono"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/$version/$file_name"

    install_external_font "$file_name" "$install_dir" "$font_family" "$download_url"
}

install_external_julia_mono_font() {
    local version="$EXTERNAL_VERSION_JULIA_MONO"
    local file_name="JuliaMono.zip"
    local install_dir="JuliaMono"
    local font_family="JuliaMono"
    local download_url="https://github.com/cormullion/juliamono/releases/download/$version/$file_name"

    install_external_font "$file_name" "$install_dir" "$font_family" "$download_url"
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
    run_cmd mkdir -p "$gtk_theme_dir" "$kvantum_theme_dir" || return 1

    local gtk_paths=(
        assets cinnamon gnome-shell gtk-2.0 gtk-3.0 gtk-4.0
        metacity-1 xfwm4 index.theme
    )

    for path in "${gtk_paths[@]}"; do
        run_cmd cp -a "$source_dir/$path" "$gtk_theme_dir/" || return 1
    done

    run_cmd cp -a "$source_dir/kde/kvantum/Nordic/." \
        "$kvantum_theme_dir/" || return 1
    run_cmd kvantummanager --set Nordic || return 1

    info "Nordic theme installed successfully"
)

install_external_zen_browser() {
    install_flathub_package app.zen_browser.zen
}
