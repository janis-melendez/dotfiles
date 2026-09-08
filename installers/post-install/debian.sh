#!/usr/bin/env bash

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing post-install/debian.sh}"

# --- Sources ---
source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/run-command.sh"

# --- Setup functions ---
configure_lightdm_wayland_sessions() {
    local config_dir="$DOTFILES_DIR/installers/config/lightdm"
    local wrapper="$config_dir/lightdm-session-wrapper"
    local lightdm_config="$config_dir/90-wayland-session-wrapper.conf"

    if [[ ! -x /usr/sbin/lightdm ]]; then
        info "Skipping LightDM Wayland session configuration: LightDM is not installed"
        return 0
    fi

    info "Configuring LightDM for native Wayland sessions"

    run_cmd sudo install -Dm755 \
        "$wrapper" \
        /usr/local/libexec/lightdm-session-wrapper || return 1
    run_cmd sudo install -Dm644 \
        "$lightdm_config" \
        /etc/lightdm/lightdm.conf.d/90-wayland-session-wrapper.conf || return 1
}

# TODO: Inspect upstream `configure.sh`. Check TODO.md for more details
configure_rodecaster_pipewire() {
    warn "Skipping configure_rodecaster_pipewire until upstream script has been verified"
    return 0

    # install_url="https://parzival-space.github.io/rodecaster-pro-2-virtual-devices-pipewire/configure.sh"

    # info "Configuring Rodecaster Pro 2 / Rodecaseter Duo"

    # # NOTE:
    # # Do not use run_cmd here
    # # Dry-run is checked before this pipeline so curl does not run
    # if [[ "${DRY_RUN:-false}" == true ]]; then
    #     # shellcheck disable=SC2016
    #     printf '+ curl -sfL %q | sh -s - --install\n' "$install_url"
    #     return 0
    # fi

    # # NOTE: installer detects the connected device automatically and selects the matching template for supported Pro II and Duo models.
    # curl -sfL "$install_url" | sh -s - --install
}

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
    configure_lightdm_wayland_sessions
    configure_rodecaster_pipewire

    print_next_steps
}
