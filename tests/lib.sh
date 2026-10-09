# Shared test helpers. Sourced by tests/run.sh.
# Assertions call `fail`, which exits the test's subshell. Don't rely on `set -e`
# inside tests: bash ignores it in the `if ( ... )` the runner uses.

# cd + pwd normalises the path (TMPDIR ends in "/"), the same way install.sh resolves REPO_DIR.
TMP_ROOT="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/mt-tests.XXXXXX")" && pwd)"
# chmod first: some tests make directories read-only.
trap 'chmod -R u+w "$TMP_ROOT" 2>/dev/null; rm -rf "$TMP_ROOT"' EXIT

fail() { echo "  assertion failed: $*"; exit 1; }
assert_file() { [ -f "$1" ] || fail "expected file $1"; }
assert_no_file() { [ ! -e "$1" ] || fail "expected nothing at $1"; }
assert_contains() { grep -qF -- "$2" "$1" || fail "expected $1 to contain: $2"; }
assert_not_contains() { ! grep -qF -- "$2" "$1" || fail "expected $1 not to contain: $2"; }
assert_eq() { [ "$1" = "$2" ] || fail "expected [$2], got [$1]"; }
# assert_count <file> <text> <n>: <text> occurs on exactly <n> lines of <file>
assert_count() {
  local n
  n=$(grep -cF -- "$2" "$1" || true)
  [ "$n" = "$3" ] || fail "expected $3 line(s) with '$2' in $1, got $n"
}

new_home() { mktemp -d "$TMP_ROOT/home.XXXXXX"; }

# One line per config file: <repo path>|<destination relative to $HOME>
expected_config_files() {
  cat <<'LIST'
config/ghostty/config|.config/ghostty/config
config/starship.toml|.config/starship.toml
config/bat/config|.config/bat/config
config/bat/themes/tokyonight_storm.tmTheme|.config/bat/themes/tokyonight_storm.tmTheme
config/helix/config.toml|.config/helix/config.toml
config/micro/settings.json|.config/micro/settings.json
config/micro/colorschemes/tokyonight.micro|.config/micro/colorschemes/tokyonight.micro
config/btop/btop.conf|.config/btop/btop.conf
config/lazygit/config.yml|Library/Application Support/lazygit/config.yml
config/glow/tokyonight-storm.json|Library/Preferences/glow/tokyonight-storm.json
config/glow/glow.yml|Library/Preferences/glow/glow.yml
LIST
}

# run_kit <home> <zsh commands> [VAR=value...]
# Sources zsh/kit.zsh in an interactive zsh (no rc files) on a pseudo-terminal,
# then runs <zsh commands>. Extra VAR=value arguments override the environment.
run_kit() {
  local home="$1" cmds="$2"
  shift 2
  OUT="$home.kit.out"
  script -q "$OUT" env -i HOME="$home" PATH="$PATH" TERM=xterm-256color "$@" \
    zsh -f -i -c "source \"$REPO_DIR/zsh/kit.zsh\"; $cmds; print -r -- KIT-DONE" \
    </dev/null >/dev/null 2>&1
}

assert_no_shell_errors() {
  local pattern
  for pattern in "not found" "no such file" "can't" "parse error" "bad pattern"; do
    assert_not_contains "$1" "$pattern"
  done
}

# run_install <home> [install.sh args...]
# Runs install.sh with /bin/bash (the macOS 3.2 one colleagues have), a clean environment
# and <home> as both HOME and working directory. Sets OUT (output file) and STATUS.
run_install() {
  local home="$1"
  shift
  OUT="$home.out"
  (cd "$home" && env -i HOME="$home" PATH="${TEST_PATH:-$PATH}" SHELL="${TEST_SHELL:-/bin/zsh}" \
    GIT_CONFIG_NOSYSTEM=1 /bin/bash "${INSTALL_SH:-$REPO_DIR/install.sh}" "$@") >"$OUT" 2>&1
  STATUS=$?
}

assert_dir_empty() { [ -z "$(ls -A "$1")" ] || fail "expected $1 to be empty, has: $(ls -A "$1")"; }

# snapshot <dir>: checksums of every file under <dir>, plus symlinks, sorted
snapshot() {
  (cd "$1" && { find . -type f -print0 | xargs -0 shasum; find . -type l; } | sort)
}
