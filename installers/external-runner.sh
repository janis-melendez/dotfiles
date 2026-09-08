#!/usr/bin/env bash
# shellcheck disable=SC1090

: "$DOTFILES_DIR:?DOTFILES_DIR must be set before sourcing installers/external-runner.sh"

# --- Sources ---
source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/print-list.sh"
source "$DOTFILES_DIR/lib/run-command.sh"

# --- Loaders ---
load_common_external_installers() {
    local common_file="$DOTFILES_DIR/installers/external/common.sh"

    if [[ ! -f "$common_file" ]]; then
        return 0
    fi

    source "$common_file"
}

load_os_external_installers() {
    local os="$1"
    local external_file="$DOTFILES_DIR/installers/external/$os.sh"

    if [[ ! -f "$external_file" ]]; then
        error "No external installers found for OS: $os"
        return 1
    fi

    source "$external_file"
}

load_external_installers() {
    local os="$1"

    load_common_external_installers || return 1
    load_os_external_installers "$os" || return 1
}

# --- Dispatch ---
install_external_tool () {
    local tool="$1"
    local installer="install_external_${tool}"

    if ! declare -F "$installer" >/dev/null; then
        error "Missing external installer: $installer"
        return 1
    fi

    "$installer"
}

# --- Prepare external dependencies ---
prepare_flathub() {
    if [[ "${PROFILE:-desktop}" != "desktop" ]]; then
        return 0
    fi

    if [[ "$(uname -s)" != "Linux" ]]; then
        return 0
    fi

    info "Configuring Flathub repository"

    # During dry-run, Flatpak may not exist yet because package installation
    # commands were only printed
    if [[ "${DRY_RUN:-false}" != true ]] && ! command -v flatpak >/dev/null 2>&1; then
        warn "Flatpak is not installed; skipping Flathub setup"
        return 0
    fi

    run_cmd sudo flatpak remote-add \
        --if-not-exists \
        flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
}

prepare_rust_toolchain() {
    info "Installing rust stable toolchain"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        run_cmd rustup default stable
        return 0
    fi

    command -v rustup >/dev/null 2>&1 || return 0

    local installer
    installer=$(command -v rustup-init || command -v rustup) || return 0

    if ! rustc >/dev/null 2>&1; then
        run_cmd "$installer" -y --default-toolchain stable
        source "$HOME/.cargo/env" 2>/dev/null || true
    fi

    if ! rustup show active-toolchain >/dev/null 2>&1; then
        info "Toolchain missing from environment. Forcing network download..."
        run_cmd toolchain install stable
        run_cmd rustup default stable
    fi
}

prepare_external_dependencies() {
    prepare_flathub
    prepare_rust_toolchain
}

# --- Public entrypoint ---
# Runs external installer IDs by mapping each ID to install_external_<id>.
run_external_installs() {
    local os="$1"
    shift

    local tools=("$@")
    local tool
    local failed_tools=()

    load_external_installers "$os"

    section "External Tools"

    if (( ${#tools[@]} == 0 )); then
        info "No external tools configured"
        return 0
    fi

    prepare_external_dependencies

    info "Installing external tools: ${#tools[@]}"
    print_list "${tools[@]}"
    printf '\n'

    for tool in "${tools[@]}"; do
        if ! install_external_tool "$tool"; then
            failed_tools+=("$tool")
        fi
    done

    if (( ${#failed_tools[@]} > 0 )); then
        error "External tools failed:"
        print_list "${failed_tools[@]}" >&2
        return 1
    fi
}
