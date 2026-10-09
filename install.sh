#!/bin/bash
# modern-terminal installer. Adds to your setup and never overwrites a file,
# so it's safe to run again. See README.md for what it changes.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_BREW=0
FAILED=0

usage() { echo "Usage: ./install.sh [--skip-brew]"; }

for arg in "$@"; do
  case "$arg" in
    --skip-brew) SKIP_BREW=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

say() { printf '%s\n' "$*"; }

# pretty <path>: the path with $HOME shown as ~
pretty() {
  local tilde='~'
  printf '%s' "${1/#"$HOME"/$tilde}"
}

preflight() {
  if [ "$(uname -s)" != "Darwin" ]; then
    say "modern-terminal only supports macOS." >&2
    exit 1
  fi
  if [ "$SKIP_BREW" -eq 0 ] && ! command -v brew >/dev/null 2>&1; then
    say "Homebrew is not installed. Install it first (see https://brew.sh):" >&2
    # shellcheck disable=SC2016  # printed for the user to copy, not expanded here
    say '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' >&2
    say "Then run ./install.sh again." >&2
    exit 1
  fi
  case "${SHELL:-}" in
    */zsh) ;;
    *) say "Warning: your login shell is not zsh (${SHELL:-unknown}). The shell setup only works in zsh." ;;
  esac
}

install_packages() {
  if [ "$SKIP_BREW" -eq 1 ]; then
    say "Skipping Homebrew packages (--skip-brew)."
    return
  fi
  say "Installing Homebrew packages..."
  if ! brew bundle --file "$REPO_DIR/Brewfile"; then
    say "brew bundle failed, so no config was changed. Fix the error above and run ./install.sh again." >&2
    exit 1
  fi
}

MARKER="# modern-terminal"

add_loader() {
  local zshrc="$HOME/.zshrc"
  if [ -f "$zshrc" ] && grep -qF "$MARKER" "$zshrc"; then
    say "skipped: ~/.zshrc already loads modern-terminal"
    return
  fi
  # Start on a fresh line even if the file doesn't end with a newline.
  if [ -s "$zshrc" ] && [ -n "$(tail -c 1 "$zshrc")" ]; then
    printf '\n' >> "$zshrc"
  fi
  # >> writes through a symlink, so a ~/.zshrc managed elsewhere stays a link.
  printf '%s\nsource "%s/zsh/kit.zsh"\n' "$MARKER" "$REPO_DIR" >> "$zshrc"
  say "installed: loader line in ~/.zshrc"
}

add_git_include() {
  local include="$REPO_DIR/git/delta.gitconfig" current
  current=$(git config --global --get-all include.path || true)
  if grep -qxF "$include" <<<"$current"; then
    say "skipped: git already includes delta.gitconfig"
    return
  fi
  git config --global --add include.path "$include"
  say "installed: git include for delta.gitconfig"
}

# copy_if_missing <repo path> <destination>
# Copies a file unless something already exists at the destination.
# Every copy replaces __HOME__ with your home directory (used by glow.yml).
copy_if_missing() {
  local src="$REPO_DIR/$1" dest="$2" home_escaped
  if [ -e "$dest" ]; then
    say "skipped (exists): $(pretty "$dest")"
    return
  fi
  home_escaped=$(printf '%s' "$HOME" | sed 's/[&|\\]/\\&/g')
  if mkdir -p "$(dirname "$dest")" 2>/dev/null &&
     sed "s|__HOME__|$home_escaped|g" "$src" > "$dest" 2>/dev/null; then
    say "installed: $(pretty "$dest")"
  else
    say "FAILED: could not write $(pretty "$dest")" >&2
    FAILED=1
  fi
}

copy_configs() {
  local config="$HOME/.config"
  local app_support="$HOME/Library/Application Support"
  local ghostty_alt="$app_support/com.mitchellh.ghostty/config"

  # Ghostty also reads its config from Application Support; either location counts.
  if [ -e "$ghostty_alt" ]; then
    say "skipped (exists): $(pretty "$ghostty_alt")"
  else
    copy_if_missing config/ghostty/config "$config/ghostty/config"
  fi
  copy_if_missing config/starship.toml "$config/starship.toml"
  copy_if_missing config/bat/config "$config/bat/config"
  copy_if_missing config/bat/themes/tokyonight_storm.tmTheme "$config/bat/themes/tokyonight_storm.tmTheme"
  copy_if_missing config/helix/config.toml "$config/helix/config.toml"
  copy_if_missing config/micro/settings.json "$config/micro/settings.json"
  copy_if_missing config/micro/colorschemes/tokyonight.micro "$config/micro/colorschemes/tokyonight.micro"
  copy_if_missing config/btop/btop.conf "$config/btop/btop.conf"
  copy_if_missing config/lazygit/config.yml "$app_support/lazygit/config.yml"
  copy_if_missing config/glow/tokyonight-storm.json "$HOME/Library/Preferences/glow/tokyonight-storm.json"
  copy_if_missing config/glow/glow.yml "$HOME/Library/Preferences/glow/glow.yml"
}

# bat (and delta, which uses bat's themes) only sees new theme files after a cache rebuild.
build_bat_cache() {
  command -v bat >/dev/null 2>&1 || return 0
  # Capture first: with pipefail, `bat | grep -q` can fail when grep exits early.
  local themes
  themes=$(bat --list-themes --color=never 2>/dev/null || true)
  if grep -qx "tokyonight_storm" <<<"$themes"; then
    return 0
  fi
  if bat cache --build >/dev/null 2>&1; then
    say "installed: bat theme cache"
  else
    say "FAILED: bat cache --build" >&2
    FAILED=1
  fi
}

main() {
  preflight
  install_packages
  say ""
  say "Shell and git:"
  add_loader
  add_git_include
  say ""
  say "Config files (only added where you don't have one):"
  copy_configs
  build_bat_cache
  say ""
  if [ "$FAILED" -ne 0 ]; then
    say "Finished with errors: see the FAILED lines above." >&2
    exit 1
  fi
  say "Done. Open a new terminal window to start using it."
}

main
