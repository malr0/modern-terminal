# shellcheck shell=bash
# install.sh: the ~/.zshrc loader line and the git include.

git_includes() { env -i HOME="$1" GIT_CONFIG_NOSYSTEM=1 PATH="$PATH" git config --global --get-all include.path; }

test_install_adds_loader_and_git_include() {
  local home; home=$(new_home)
  run_install "$home" --skip-brew
  assert_eq "$STATUS" "0"
  assert_contains "$home/.zshrc" "# modern-terminal"
  assert_contains "$home/.zshrc" "source \"$REPO_DIR/zsh/kit.zsh\""
  assert_eq "$(git_includes "$home")" "$REPO_DIR/git/delta.gitconfig"
  assert_contains "$OUT" "installed: loader line in ~/.zshrc"
  assert_contains "$OUT" "installed: git include for delta.gitconfig"
}

test_install_twice_adds_everything_once() {
  local home; home=$(new_home)
  run_install "$home" --skip-brew
  run_install "$home" --skip-brew
  assert_eq "$STATUS" "0"
  assert_count "$home/.zshrc" "# modern-terminal" 1
  assert_eq "$(git_includes "$home" | grep -c delta.gitconfig)" "1"
  assert_contains "$OUT" "skipped: ~/.zshrc already loads modern-terminal"
  assert_contains "$OUT" "skipped: git already includes delta.gitconfig"
}

test_install_appends_after_zshrc_without_trailing_newline() {
  local home; home=$(new_home)
  printf 'export FOO=1' > "$home/.zshrc"
  run_install "$home" --skip-brew
  assert_eq "$(sed -n 1p "$home/.zshrc")" "export FOO=1"
  assert_eq "$(sed -n 2p "$home/.zshrc")" "# modern-terminal"
}

test_install_keeps_symlinked_zshrc() {
  local home; home=$(new_home)
  mkdir -p "$home/dotfiles"
  echo 'export FOO=1' > "$home/dotfiles/zshrc"
  ln -s "$home/dotfiles/zshrc" "$home/.zshrc"
  run_install "$home" --skip-brew
  [ -L "$home/.zshrc" ] || fail "$home/.zshrc is no longer a symlink"
  assert_contains "$home/dotfiles/zshrc" "# modern-terminal"
}

test_install_keeps_existing_git_settings() {
  local home; home=$(new_home)
  env -i HOME="$home" PATH="$PATH" git config --global user.email someone@example.com
  env -i HOME="$home" PATH="$PATH" git config --global include.path "$home/other.gitconfig"
  run_install "$home" --skip-brew
  assert_eq "$(env -i HOME="$home" PATH="$PATH" git config --global user.email)" "someone@example.com"
  assert_contains <(git_includes "$home") "$home/other.gitconfig"
  assert_contains <(git_includes "$home") "$REPO_DIR/git/delta.gitconfig"
}

test_install_from_path_with_spaces() {
  local home clone; home=$(new_home); clone="$TMP_ROOT/my repos/modern-terminal"
  mkdir -p "$clone"
  (cd "$REPO_DIR" && tar --exclude .git -cf - .) | (cd "$clone" && tar -xf -)
  INSTALL_SH="$clone/install.sh" run_install "$home" --skip-brew
  assert_eq "$STATUS" "0"
  assert_contains "$home/.zshrc" "source \"$clone/zsh/kit.zsh\""
  assert_eq "$(git_includes "$home")" "$clone/git/delta.gitconfig"
  # The generated ~/.zshrc must actually load in zsh.
  env -i HOME="$home" PATH="$PATH" zsh -f -c "source \"$home/.zshrc\" && print -r -- ZSHRC-OK" \
    > "$home.zsh.out" 2>&1 </dev/null
  assert_contains "$home.zsh.out" "ZSHRC-OK"
}

test_install_repairs_loader_and_include_after_clone_moves() {
  local home old new; home=$(new_home); old="$TMP_ROOT/old/modern-terminal"; new="$TMP_ROOT/new/modern-terminal"
  copy_repo "$old"
  INSTALL_SH="$old/install.sh" run_install "$home" --skip-brew
  mkdir -p "$TMP_ROOT/new"
  mv "$old" "$new"
  INSTALL_SH="$new/install.sh" run_install "$home" --skip-brew
  assert_eq "$STATUS" "0"
  assert_count "$home/.zshrc" "# modern-terminal" 1
  assert_contains "$home/.zshrc" "source \"$new/zsh/kit.zsh\""
  assert_not_contains "$home/.zshrc" "$old"
  assert_contains "$OUT" "updated: loader line in ~/.zshrc"
  assert_eq "$(git_includes "$home")" "$new/git/delta.gitconfig"
  assert_contains "$OUT" "removed: stale git include $old/git/delta.gitconfig"
}

test_install_leaves_git_alone_when_user_has_own_pager() {
  local home; home=$(new_home)
  env -i HOME="$home" PATH="$PATH" git config --global core.pager "less -FRX"
  run_install "$home" --skip-brew
  assert_eq "$STATUS" "0"
  assert_eq "$(git_includes "$home")" ""
  assert_eq "$(env -i HOME="$home" PATH="$PATH" git config core.pager)" "less -FRX"
  assert_contains "$OUT" "skipped: your git config already sets core.pager"
}

test_install_leaves_git_alone_when_user_has_delta_settings() {
  local home; home=$(new_home)
  env -i HOME="$home" PATH="$PATH" git config --global delta.side-by-side false
  run_install "$home" --skip-brew
  assert_eq "$(git_includes "$home")" ""
  assert_contains "$OUT" "skipped: your git config already sets delta.side-by-side"
}
