# shellcheck shell=bash
# Repo-wide checks: Brewfile contents and no personal data in shipped files.

brewfile_entries() {
  brew bundle list --all --file="$REPO_DIR/Brewfile" 2>/dev/null | grep -v -e '^==>' -e '^✔' | sort
}

test_brewfile_lists_core_tools() {
  local expected actual
  expected=$(printf '%s\n' ast-grep bat btop eza fd font-jetbrains-mono-nerd-font fzf gh ghostty \
    git-delta glow helix jq lazygit micro ripgrep sd starship zoxide zsh-autosuggestions \
    zsh-syntax-highlighting | sort)
  actual=$(brewfile_entries) || fail "brew bundle could not parse the Brewfile"
  assert_eq "$actual" "$expected"
}

test_brewfile_has_no_agents() {
  local entries
  entries=$(brewfile_entries)
  for name in herdr claude-code codex; do
    ! grep -qx "$name" <<<"$entries" || fail "Brewfile must not install $name"
  done
}

test_repo_has_no_personal_data() {
  # Patterns are split so this file doesn't match itself.
  local hits
  hits=$(grep -rIl --exclude-dir=.git --exclude-dir=superpowers --exclude-dir=.superpowers \
    -e '/Users/'"mattias" -e 'epical''group' "$REPO_DIR" || true)
  assert_eq "$hits" ""
}
