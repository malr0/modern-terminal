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

main() {
  preflight
  install_packages
  say ""
  say "Shell and git:"
  add_loader
  add_git_include
  # -- config file steps (Task 6) --
  say ""
  if [ "$FAILED" -ne 0 ]; then
    say "Finished with errors: see the FAILED lines above." >&2
    exit 1
  fi
  say "Done. Open a new terminal window to start using it."
}

main
