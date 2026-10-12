# shellcheck shell=bash
# install.sh: how it calls brew bundle. A fake brew records its arguments and the
# casks it was told to skip, so nothing is installed.

# fake_brew <dir>: puts a brew in <dir> that logs to <dir>/brew.log
fake_brew() {
  mkdir -p "$1"
  cat > "$1/brew" <<'EOF'
#!/bin/sh
log="$(dirname "$0")/brew.log"
echo "args: $*" >> "$log"
echo "cask-skip: ${HOMEBREW_BUNDLE_CASK_SKIP:-}" >> "$log"
EOF
  chmod +x "$1/brew"
}

test_install_brew_bundle_does_not_upgrade() {
  local home bin; home=$(new_home); bin="$home.bin"
  fake_brew "$bin"
  TEST_PATH="$bin:$PATH" run_install "$home"
  assert_eq "$STATUS" "0"
  assert_contains "$bin/brew.log" "args: bundle --no-upgrade --file $REPO_DIR/Brewfile"
}

test_install_skips_ghostty_cask_when_app_exists() {
  local home bin; home=$(new_home); bin="$home.bin"
  fake_brew "$bin"
  mkdir -p "$home/Applications/Ghostty.app"
  TEST_PATH="$bin:$PATH" run_install "$home"
  assert_eq "$STATUS" "0"
  assert_contains "$bin/brew.log" "cask-skip: ghostty"
  assert_contains "$OUT" "skipped (already installed): Ghostty"
}

test_install_skips_font_cask_when_font_exists() {
  local home bin; home=$(new_home); bin="$home.bin"
  fake_brew "$bin"
  mkdir -p "$home/Library/Fonts"
  touch "$home/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf"
  TEST_PATH="$bin:$PATH" run_install "$home"
  assert_eq "$STATUS" "0"
  assert_contains "$bin/brew.log" "font-jetbrains-mono-nerd-font"
  assert_contains "$OUT" "skipped (already installed): JetBrains Mono Nerd Font"
}

test_install_keeps_font_cask_when_font_is_missing() {
  local home bin; home=$(new_home); bin="$home.bin"
  fake_brew "$bin"
  TEST_PATH="$bin:$PATH" run_install "$home"
  assert_eq "$STATUS" "0"
  assert_not_contains "$bin/brew.log" "font-jetbrains-mono-nerd-font"
  assert_not_contains "$OUT" "skipped (already installed): JetBrains Mono Nerd Font"
}
