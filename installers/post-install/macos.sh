#!/usr/bin/env bash

: "${DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing post-install/macos.sh}"

# --- Sources ---
source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/run-command.sh"

# --- Setup functions ---

# --- Next steps ---
print_next_steps() {
    section "Next steps"

    cat <<EOF
    - Restart your terminal to start a new Zsh session
    - Install Zoom
    - Sign in to 1Password, Proton VPN, and Zoom
    - Import your SSH and GPG keys
EOF
}

configure_browser_extensions() {
    local chrome_policy="$HOME/dotfiles/modules/browsers/policies/chrome.json"

    if [[ ! -d "/Applications/Google Chrome.app" ]]; then
        return 0
    fi

    if [[ ! -f "$chrome_policy" ]]; then
        info "Chrome extension policy not found: $chrome_policy"
        return 0
    fi

    info "Configuring Google Chrome extensions"

    local extension_settings
    extension_settings="$(jq -c '.ExtensionSettings' "$chrome_policy")" ||
        return 1

    run_cmd plutil \
        -replace ExtensionSettings \
        -json "$extension_settings" \
        "$HOME/Library/Preferences/com.google.Chrome.plist" ||
        return 1

    run_cmd killall cfprefsd 2>/dev/null || true
}

# --- Public entrypoint ---
run_os_post_install() {
    configure_browser_extensions
    print_next_steps
}
