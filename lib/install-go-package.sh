#!/usr/bin/env bash

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing install-go-package.sh}"

source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/run-command.sh"

install_go_package() {
    local module="$1"
    local version="$2"

    if ! command -v go >/dev/null 2>&1; then
        warn "Go is required to install $module"
        return 1
    fi

    info "Installing $module $version"
    run_cmd go install "$module@$version"
}
