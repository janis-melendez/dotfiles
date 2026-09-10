# Dotfiles scripts

## `install`

Installs the main personal-machine packages and external tools for the detected
operating system.

```bash
./install
```

Useful options:

```bash
./install -n              # Preview commands
./install -p core         # Minimal profile
./install -p headless     # Development tools without desktop software
./install -p desktop      # Full workstation profile
```

Run `./install -h` for all options.

## `stow-modules`

Stows or unstows personal dotfile modules.

```bash
./stow-modules
./stow-modules nvim zsh tmux
./stow-modules -u nvim
./stow-modules -r
```

Run `./stow-modules -h` for all options.
