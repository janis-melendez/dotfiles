#!/usr/bin/env bash
# shellcheck disable=SC2034

# ─────────────────────────────────────────────────────────────
# Package manifests
# ─────────────────────────────────────────────────────────────

# minimal terminal/dotfiles setup:
# - shell, editor, search, navigation, archive, and dotfile tools
CORE_PACKAGES=(
    7zip
    bat
    curl
    diffutils
    fd
    ffmpeg
    fzf
    git
    gzip
    jq
    neovim
    poppler
    restic
    resvg
    ripgrep
    stow
    tar
    the_silver_searcher
    tmux
    unzip
    yazi
    zoxide
    zsh
)

# headless development/build tools:
# - compilers, runtimes, build tools, container tools, linters, formatters,
#   and project workflow tools
HEADLESS_PACKAGES=(
    base-devel
    bun
    cmake
    docker
    docker-buildx
    docker-compose
    go
    lazygit
    nodejs
    npm
    python
    python-pip
    rustup
    shellcheck
    shfmt
    tree-sitter-cli
)

# GUI/workstation additions:
# - window managers, launchers, graphical terminals, editors, and GUI apps
DESKTOP_PACKAGES=(
    # General desktop
    flatpak
    ghostty
    weechat
    zenity

    # Theming tools and engines
    lxappearance
    kvantum
    kvantum-qt5
    qt5ct
    qt6ct

    # Adwaita Theme
    adw-gtk-theme
    gnome-themes-extra

    # Breeze theme
    breeze
    breeze5
    breeze-gtk

    # Papirus icons
    papirus-icon-theme

    # Desktop audio
    pipewire
    pipewire-alsa
    pipewire-pulse
    wireplumber

    # Audio controls and diagnostics
    alsa-utils
    pavucontrol

    # Camera controls and diagnostics
    v4l-utils

    # Keyboard diagnostics
    libinput-tools
    wev
    evtest

    # Shared window-manager tooling
    dunst
    polkit-kde-agent

    # X11 monitor tooling
    xorg-xrandr
    feh

    # Desktop portals
    gnome-keyring
    xdg-desktop-portal-gtk

    # Shared Wayland tooling
    # mako
    waybar
    wl-clipboard
    xorg-xwayland

    # Hyprland-specific tooling
    hyprland
    hypridle
    hyprlock
    xdg-desktop-portal-hyprland

    # Niri-specific tooling
    niri
    nautilus
    xwayland-satellite
    xdg-desktop-portal-gnome

    # Sway-specific tooling
    sway
    swayidle
    swaylock
    wlsunset
    xdg-desktop-portal-wlr
)

# ─────────────────────────────────────────────────────────────
# External tools manifests
# ─────────────────────────────────────────────────────────────

# NOTE:
# External installer IDs.
# Each value maps to a function named install_external_<id>.
EXTERNAL_CORE=(
    herdr

    # Manages zsh plugins
    antidote

    # Manual alternative to Antidote
    # zsh_plugins
)

EXTERNAL_HEADLESS=(
    claude_code
    codex
    workmux
)

EXTERNAL_DESKTOP=(
    autotiling
    dejadup

    # Fonts:
    dejavu_font
    fira_code_font
    hack_font
    julia_mono_font

    # Cursor theme:
    bibata_cursor_theme

    # GTK and Qt/Gvantum theme:
    graphite_theme

    # GTK and Qt/Gvantum theme:
    nordic_theme
)

# ─────────────────────────────────────────────────────────────
# Stow module manifests
# ─────────────────────────────────────────────────────────────
# dotfile modules for the minimal terminal setup
CORE_STOW_MODULES=(
    bat
    nvim
    ohmyposh
    tmux
    zsh
    linux-scripts
)

# dotfile modules for headless development/build tooling
HEADLESS_STOW_MODULES=(
    lazygit
)

# dotfile modules for GUI/workstation setup
DESKTOP_STOW_MODULES=(
    dunst
    ghostty
    hexchat
    rofi
    niri
    sway
    theme
    weechat
    wlsunset
)
