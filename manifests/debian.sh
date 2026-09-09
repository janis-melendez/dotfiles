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
    fd-find
    ffmpeg
    git
    gzip
    jq
    poppler-utils
    ripgrep
    silversearcher-ag
    stow
    tar
    tmux
    unzip
    zsh
)

# headless development/build tools:
# - compilers, runtimes, build tools, container tools, linters, formatters,
#   and project workflow tools
HEADLESS_PACKAGES=(
    build-essential
    cmake
    docker-buildx
    docker-compose-v2
    docker.io
    golang-go
    ipython3
    nodejs
    pipx
    python3
    python3-pip
    python3-venv
    restic
    rustup
    shellcheck
    shfmt
    tree-sitter-cli
    uuid-dev
)

# GUI/workstation additions:
# - window managers, launchers, graphical terminals, editors, and GUI apps
DESKTOP_PACKAGES=(
    # General desktop
    1password
    flatpak
    gdm3
    ghostty
    google-chrome-stable
    helium-bin
    hexchat
    xclip
    weechat
    zenity

    # Theming tools and engines
    lxappearance
    qt5ct
    qt6ct
    qt-style-kvantum
    qt5-style-kvantum
    qt6-style-kvantum

    # Adwaita theme
    adwaita-qt
    adwaita-qt6
    gnome-themes-extra

    # Arc Theme
    arc-kde
    arc-theme

    # Breeze theme
    breeze-gtk-theme
    kde-style-breeze
    kde-style-breeze-qt5

    # Papirus icons
    papirus-icon-theme

    # Desktop audio
    pipewire-audio

    # Audio controls and diagnostics
    alsa-utils
    pavucontrol
    pulseaudio-utils

    # Camera controls and diagnostics
    v4l-utils

    # Keyboard diagnostics
    libinput-tools
    wev
    evtest

    # Desktop portals
    gnome-keyring
    xdg-desktop-portal-gtk

    # Shared window-manager tooling
    dunst
    polkit-kde-agent-1
    python3-i3ipc
    rofi

    # i3 / X11 tooling
    i3
    picom
    feh

    # Shared Wayland tooling
    # mako
    swaybg
    swaylock
    swayidle
    waybar
    wl-clipboard
    wlsunset
    xwayland

    # Sway-specific tooling
    slurp
    sway
    xdg-desktop-portal-wlr
)

# ─────────────────────────────────────────────────────────────
# External tools manifests
# ─────────────────────────────────────────────────────────────

# NOTE:
# External installer IDs.
# Each value maps to a function named install_external_<id>.
EXTERNAL_CORE=(
    fzf
    herdr
    neovim
    oh_my_posh
    resvg
    yazi
    zoxide

    # Manages zsh plugins
    antidote

    # Manual alternative to Antidote
    # zsh_plugins
)

EXTERNAL_HEADLESS=(
    bun
    claude_code
    codex
    lazydocker
    lazygit
    workmux
)

EXTERNAL_DESKTOP=(
    autotiling
    dejadup
    proton_mail
    proton_pass
    zen_browser

    # Fonts:
    dejavu_font
    hack_font
    fira_code_font
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
    i3
    picom
    rofi
    sway
    theme
    weechat
    wlsunset
)
