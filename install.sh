#!/bin/bash
# modern-terminal installer. Adds to your setup and never overwrites a file,
# so it's safe to run again. See README.md for what it changes.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_BREW=0
FAILED=0
# Where bat, helix, micro, btop and Ghostty look for their config.
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

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

# find_installed_casks: sets SKIP_CASKS to the casks whose app or font is already there,
# for example from a download. brew can't install a cask over them, and that error
# would stop brew bundle.
SKIP_CASKS=""
find_installed_casks() {
  local dir font
  for dir in /Applications "$HOME/Applications"; do
    if [ -e "$dir/Ghostty.app" ]; then
      say "skipped (already installed): Ghostty"
      SKIP_CASKS="ghostty"
      break
    fi
  done
  for font in "$HOME"/Library/Fonts/JetBrainsMonoNerdFont*.ttf /Library/Fonts/JetBrainsMonoNerdFont*.ttf; do
    if [ -e "$font" ]; then
      say "skipped (already installed): JetBrains Mono Nerd Font"
      SKIP_CASKS="${SKIP_CASKS:+$SKIP_CASKS }font-jetbrains-mono-nerd-font"
      break
    fi
  done
}

install_packages() {
  if [ "$SKIP_BREW" -eq 1 ]; then
    say "Skipping Homebrew packages (--skip-brew)."
    return
  fi
  say "Installing Homebrew packages..."
  find_installed_casks
  # --no-upgrade: tools you already have stay at their current version.
  if ! HOMEBREW_BUNDLE_CASK_SKIP="$SKIP_CASKS" brew bundle --no-upgrade --file "$REPO_DIR/Brewfile"; then
    say "brew bundle failed, so no config was changed. Fix the error above and run ./install.sh again." >&2
    exit 1
  fi
}

MARKER="# modern-terminal"

add_loader() {
  local zshrc="$HOME/.zshrc" line="source \"$REPO_DIR/zsh/kit.zsh\"" updated
  if [ -f "$zshrc" ] && grep -qF "$MARKER" "$zshrc"; then
    if grep -qxF "$line" "$zshrc"; then
      say "skipped: ~/.zshrc already loads modern-terminal"
      return
    fi
    # The clone has moved: point the kit's own line (right after the marker) here.
    # Write back with cat so a symlinked ~/.zshrc stays a symlink.
    updated=$(awk -v marker="$MARKER" -v line="$line" '
      prev == marker && /^source ".*\/zsh\/kit\.zsh"$/ { print line; prev = ""; next }
      { print; prev = $0 }' "$zshrc")
    printf '%s\n' "$updated" > "$zshrc"
    if grep -qxF "$line" "$zshrc"; then
      say "updated: loader line in ~/.zshrc"
    else
      say "FAILED: ~/.zshrc has the '$MARKER' line but no kit line after it. Fix it by hand." >&2
      FAILED=1
    fi
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
  local include="$REPO_DIR/git/delta.gitconfig" current path own
  current=$(git config --global --get-all include.path || true)

  # Drop includes left behind by a clone that has since moved.
  while IFS= read -r path; do
    case "$path" in
      */git/delta.gitconfig)
        if [ "$path" != "$include" ] && [ ! -e "$path" ]; then
          git config --global --fixed-value --unset include.path "$path"
          say "removed: stale git include $path"
        fi ;;
    esac
  done <<<"$current"

  if grep -qxF "$include" <<<"$current"; then
    say "skipped: git already includes delta.gitconfig"
    return
  fi
  # The include comes last in the file, so it would override these. Leave git alone instead.
  # (--global without --includes reads only the user's own file.)
  own=$(git config --global --name-only --get-regexp \
    '^(core\.pager|interactive\.difffilter|merge\.conflictstyle|delta\..*)$' || true)
  if [ -n "$own" ]; then
    say "skipped: your git config already sets $(head -n 1 <<<"$own"), so delta.gitconfig was not added (see README)"
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

# ghostty_config: prints the first existing Ghostty config file, if any
ghostty_config() {
  local dir file
  for dir in "$CONFIG_DIR/ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty"; do
    for file in config config.ghostty; do
      if [ -e "$dir/$file" ]; then
        printf '%s' "$dir/$file"
        return
      fi
    done
  done
}

copy_configs() {
  local config="$CONFIG_DIR" existing lazygit_dir
  # lazygit only uses XDG_CONFIG_HOME when it is set; otherwise Application Support.
  if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    lazygit_dir="$XDG_CONFIG_HOME/lazygit"
  else
    lazygit_dir="$HOME/Library/Application Support/lazygit"
  fi

  # Ghostty reads config or config.ghostty from two directories; any of them counts.
  existing=$(ghostty_config)
  if [ -n "$existing" ]; then
    say "skipped (exists): $(pretty "$existing")"
  else
    copy_if_missing config/ghostty/config "$config/ghostty/config"
  fi
  # starship reads ~/.config/starship.toml whatever XDG_CONFIG_HOME says.
  copy_if_missing config/starship.toml "$HOME/.config/starship.toml"
  copy_if_missing config/bat/config "$config/bat/config"
  copy_if_missing config/bat/themes/tokyonight_storm.tmTheme "$config/bat/themes/tokyonight_storm.tmTheme"
  copy_if_missing config/helix/config.toml "$config/helix/config.toml"
  copy_if_missing config/micro/settings.json "$config/micro/settings.json"
  copy_if_missing config/micro/colorschemes/tokyonight.micro "$config/micro/colorschemes/tokyonight.micro"
  copy_if_missing config/btop/btop.conf "$config/btop/btop.conf"
  copy_if_missing config/lazygit/config.yml "$lazygit_dir/config.yml"
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
