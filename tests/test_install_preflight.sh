# shellcheck shell=bash
# install.sh: argument handling and preflight checks.

test_install_rejects_non_macos() {
  local home bin; home=$(new_home); bin="$TMP_ROOT/fake-linux-bin"
  mkdir -p "$bin"
  printf '#!/bin/sh\necho Linux\n' > "$bin/uname"
  chmod +x "$bin/uname"
  TEST_PATH="$bin:$PATH" run_install "$home" --skip-brew
  assert_eq "$STATUS" "1"
  assert_contains "$OUT" "only supports macOS"
  assert_dir_empty "$home"
}

test_install_requires_homebrew() {
  local home; home=$(new_home)
  TEST_PATH=/usr/bin:/bin run_install "$home"
  assert_eq "$STATUS" "1"
  assert_contains "$OUT" "Homebrew is not installed"
  assert_contains "$OUT" "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
  assert_dir_empty "$home"
}

test_install_rejects_unknown_flag() {
  local home; home=$(new_home)
  run_install "$home" --nope
  assert_eq "$STATUS" "2"
  assert_contains "$OUT" "Usage: ./install.sh [--skip-brew]"
}

test_install_help() {
  local home; home=$(new_home)
  run_install "$home" --help
  assert_eq "$STATUS" "0"
  assert_contains "$OUT" "Usage: ./install.sh [--skip-brew]"
  assert_dir_empty "$home"
}

test_install_warns_when_shell_is_not_zsh() {
  local home; home=$(new_home)
  TEST_SHELL=/bin/bash run_install "$home" --skip-brew
  assert_eq "$STATUS" "0"
  assert_contains "$OUT" "your login shell is not zsh"
}

test_install_skip_brew_says_so() {
  local home; home=$(new_home)
  run_install "$home" --skip-brew
  assert_eq "$STATUS" "0"
  assert_contains "$OUT" "Skipping Homebrew packages (--skip-brew)"
  assert_contains "$OUT" "Open a new terminal window"
}
