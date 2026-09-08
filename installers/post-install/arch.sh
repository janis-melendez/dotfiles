#!/usr/bin/env bash

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing post-install/arch.sh}"

# --- Sources ---
source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/run-command.sh"

# --- Setup functions ---

# --- Next steps ---
print_next_steps() {
    section "Next steps"

    cat <<EOF
    - Log out and back in to apply Docker group membership and start a new Zsh session
    - Select your preferred desktop session at the login screen
    - Install Zoom
    - Sign in to 1Password, Proton VPN, and Zoom
    - Import your SSH and GPG keys
EOF
}

# --- Public entrypoint ---
run_os_post_install() {
    print_next_steps
}
