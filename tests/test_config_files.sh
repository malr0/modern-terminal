# shellcheck shell=bash
# The config files shipped in the repo.

test_all_config_files_present() {
  local src
  while IFS='|' read -r src _; do
    assert_file "$REPO_DIR/$src"
  done < <(expected_config_files)
}

test_glow_config_points_at_home_token() {
  assert_contains "$REPO_DIR/config/glow/glow.yml" \
    'style: "__HOME__/Library/Preferences/glow/tokyonight-storm.json"'
}

test_btop_config_sets_theme_only() {
  assert_eq "$(cat "$REPO_DIR/config/btop/btop.conf")" 'color_theme = "tokyo-storm"'
}

test_delta_gitconfig_is_valid_without_identity() {
  local list
  list=$(git config -f "$REPO_DIR/git/delta.gitconfig" --list) || fail "delta.gitconfig does not parse"
  printf '%s\n' "$list" > "$TMP_ROOT/delta.list"
  assert_contains "$TMP_ROOT/delta.list" "core.pager=delta"
  assert_contains "$TMP_ROOT/delta.list" "delta.syntax-theme=tokyonight_storm"
  assert_not_contains "$TMP_ROOT/delta.list" "user."
  assert_not_contains "$TMP_ROOT/delta.list" "credential."
}

test_glow_theme_draws_task_checkboxes() {
  # Without these, glow shows task list items with no checkbox and no bullet.
  local task
  task=$(jq -c '.task | {ticked, unticked}' "$REPO_DIR/config/glow/tokyonight-storm.json")
  assert_eq "$task" '{"ticked":"[✓] ","unticked":"[ ] "}'
}
