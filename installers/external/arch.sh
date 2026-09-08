#!/usr/bin/env bash
# Defines Arch-family external tool installs not handled by pacman

: "$DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing installers/external/arch.sh"

# --- Sources ---
source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/run-command.sh"
source "$DOTFILES_DIR/installers/external/versions.sh"

# --- Helper functions ---
is_command_available(){
    command -v "$1" &>/dev/null
}

# --- External tool installers ---
