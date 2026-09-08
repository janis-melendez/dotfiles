#!/usr/bin/env bash

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing post-install/fedora.sh}"

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

configure_dms() {
    if ! command -v niri || ! command -v dms &>dev/null; then
        info "Skipping DMS configuration: Niri or DMS is not installed"
        return 0
    fi

    info "Configuring DMS to start with Niri"

    run_cmd systemctl --user add-wants niri.service dms
}

configure_plasma_polkit_agent() {
    local source_file="$DOTFILES_DIR/installers/config/systemd/plasma-polkit-agent-niri.conf"
    local target_dir="$HOME/.config/systemd/user/plasma-polkit-agent.service.d"
    local target_file="$target_dir/niri.conf"

    if ! command -v niri >/dev/null 2>&1 ||
        ! systemctl --user cat plasma-polkit-agent.service >/dev/null 2>&1; then
        info "Skipping Plasma PolicyKit agent configuration: Niri or its user unit is unavailable"
        return 0
    fi

    info "Configuring Plasma PolicyKit agent for Niri"

    run_cmd mkdir -p "$target_dir" || return 1
    run_cmd install -m644 "$source_file" "$target_file" || return 1
    run_cmd systemctl --user daemon-reload || return 1
}

# --- Public entrypoint ---
run_os_post_install() {
    configure_dms
    configure_plasma_polkit_agent

    print_next_steps
}
