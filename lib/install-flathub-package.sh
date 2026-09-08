#!/usr/bin/env bash

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing install-flathub-package.sh}"

source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/run-command.sh"

install_flathub_package() {
    local app_id="$1"

    if ! command -v flatpak >/dev/null 2>&1; then
        warn "Flatpak is required to install $app_id"
        return 1
    fi

    info "Installing Flathub application: $app_id"
    run_cmd flatpak install --noninteractive --assumeyes flathub "$app_id"
}
