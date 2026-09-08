#!/usr/bin/env bash

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing install-cargo-package.sh}"

source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/run-command.sh"

install_cargo_package() {
    local package="$1"
    local version="$2"
    shift 2

    if ! command -v cargo >/dev/null 2>&1; then
        warn "Cargo is required to install $package"
        return 1
    fi

    info "Installing $package $version"
    run_cmd cargo install "$package" --version "$version" --locked "$@"
}
