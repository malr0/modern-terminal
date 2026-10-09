# Shared test helpers. Sourced by tests/run.sh.
# Assertions call `fail`, which exits the test's subshell. Don't rely on `set -e`
# inside tests: bash ignores it in the `if ( ... )` the runner uses.

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/mt-tests.XXXXXX")"
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
