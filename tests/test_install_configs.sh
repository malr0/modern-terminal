# shellcheck shell=bash
# install.sh: copying config files.

test_install_copies_all_configs_into_fresh_home() {
  local home src dest; home=$(new_home)
  run_install "$home" --skip-brew
  assert_eq "$STATUS" "0"
  while IFS='|' read -r src dest; do
    assert_file "$home/$dest"
    assert_contains "$OUT" "installed: ~/$dest"
    if [ "$src" != "config/glow/glow.yml" ]; then
      cmp -s "$REPO_DIR/$src" "$home/$dest" || fail "$dest differs from $src"
    fi
  done < <(expected_config_files)
}

test_install_points_glow_at_users_home() {
  local home; home=$(new_home)
  run_install "$home" --skip-brew
  assert_contains "$home/Library/Preferences/glow/glow.yml" \
    "style: \"$home/Library/Preferences/glow/tokyonight-storm.json\""
  assert_not_contains "$home/Library/Preferences/glow/glow.yml" "__HOME__"
}

test_install_never_overwrites_existing_configs() {
  local home; home=$(new_home)
  mkdir -p "$home/.config/helix" "$home/.config/bat"
  echo mine > "$home/.config/starship.toml"
  echo mine > "$home/.config/helix/config.toml"
  echo mine > "$home/.config/bat/config"
  run_install "$home" --skip-brew
  assert_eq "$STATUS" "0"
  assert_eq "$(cat "$home/.config/starship.toml")" "mine"
  assert_eq "$(cat "$home/.config/helix/config.toml")" "mine"
  assert_eq "$(cat "$home/.config/bat/config")" "mine"
  assert_contains "$OUT" "skipped (exists): ~/.config/starship.toml"
  # Theme files still land next to an existing config.
  assert_file "$home/.config/bat/themes/tokyonight_storm.tmTheme"
}

test_install_respects_ghostty_config_in_application_support() {
  local home; home=$(new_home)
  mkdir -p "$home/Library/Application Support/com.mitchellh.ghostty"
  echo mine > "$home/Library/Application Support/com.mitchellh.ghostty/config"
  run_install "$home" --skip-brew
  assert_no_file "$home/.config/ghostty/config"
  assert_contains "$OUT" "skipped (exists): ~/Library/Application Support/com.mitchellh.ghostty/config"
}

test_install_second_run_changes_nothing() {
  local home before after; home=$(new_home)
  run_install "$home" --skip-brew
  # The first run must have installed the configs, or the comparison proves nothing.
  assert_file "$home/.config/starship.toml"
  assert_file "$home/Library/Preferences/glow/glow.yml"
  before=$(snapshot "$home")
  run_install "$home" --skip-brew
  assert_eq "$STATUS" "0"
  after=$(snapshot "$home")
  assert_eq "$after" "$before"
  assert_not_contains "$OUT" "installed:"
}

test_install_continues_after_failed_copy() {
  local home; home=$(new_home)
  mkdir -p "$home/.config/micro"
  chmod 500 "$home/.config/micro"
  run_install "$home" --skip-brew
  chmod 700 "$home/.config/micro"
  assert_eq "$STATUS" "1"
  assert_contains "$OUT" "FAILED: could not write ~/.config/micro/settings.json"
  assert_contains "$OUT" "Finished with errors"
  # Files before and after the failing one are still installed.
  assert_file "$home/.config/helix/config.toml"
  assert_file "$home/.config/btop/btop.conf"
}

test_install_registers_bat_theme() {
  command -v bat >/dev/null 2>&1 || fail "bat must be installed to run this test"
  local home; home=$(new_home)
  run_install "$home" --skip-brew
  env -i HOME="$home" PATH="$PATH" bat --list-themes --color=never > "$home.themes" 2>&1
  grep -qx "tokyonight_storm" "$home.themes" || fail "tokyonight_storm not in bat --list-themes"
}

test_install_respects_ghostty_config_dot_ghostty() {
  local home dir; home=$(new_home)
  for dir in ".config/ghostty" "Library/Application Support/com.mitchellh.ghostty"; do
    rm -rf "$home/.config" "$home/Library"
    mkdir -p "$home/$dir"
    echo mine > "$home/$dir/config.ghostty"
    run_install "$home" --skip-brew
    assert_no_file "$home/.config/ghostty/config"
    assert_contains "$OUT" "skipped (exists): ~/$dir/config.ghostty"
  done
}

test_install_uses_xdg_config_home() {
  local home xdg; home=$(new_home); xdg="$home/xdg"
  TEST_XDG_CONFIG_HOME="$xdg" run_install "$home" --skip-brew
  assert_eq "$STATUS" "0"
  for f in ghostty/config bat/config bat/themes/tokyonight_storm.tmTheme helix/config.toml \
    micro/settings.json micro/colorschemes/tokyonight.micro btop/btop.conf lazygit/config.yml; do
    assert_file "$xdg/$f"
  done
  # starship and glow don't use XDG_CONFIG_HOME on macOS.
  assert_file "$home/.config/starship.toml"
  assert_file "$home/Library/Preferences/glow/glow.yml"
  assert_no_file "$home/Library/Application Support/lazygit/config.yml"
  env -i HOME="$home" XDG_CONFIG_HOME="$xdg" PATH="$PATH" bat --list-themes --color=never > "$home.themes" 2>&1
  grep -qx "tokyonight_storm" "$home.themes" || fail "tokyonight_storm not visible to bat with XDG_CONFIG_HOME"
}
