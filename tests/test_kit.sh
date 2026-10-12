# shellcheck shell=bash
# The single-quoted commands below are zsh code, expanded by zsh rather than bash.
# shellcheck disable=SC2016

# zsh/kit.zsh in a real interactive zsh.

test_kit_loads_cleanly_and_defines_commands() {
  local home; home=$(new_home)
  run_kit "$home" 'alias ll; alias lg; alias glow; whence -w rgf ff; print -r -- "EDITOR=$EDITOR VISUAL=$VISUAL"'
  assert_contains "$OUT" "KIT-DONE"
  assert_no_shell_errors "$OUT"
  assert_contains "$OUT" "ll='eza -l --icons --group-directories-first --git'"
  assert_contains "$OUT" "lg=lazygit"
  assert_contains "$OUT" "glow='glow -t'"
  assert_contains "$OUT" "rgf: function"
  assert_contains "$OUT" "ff: function"
  assert_contains "$OUT" "EDITOR=hx VISUAL=hx"
}

test_kit_keeps_existing_editor() {
  local home; home=$(new_home)
  run_kit "$home" 'print -r -- "EDITOR=$EDITOR VISUAL=$VISUAL"' EDITOR=code VISUAL=code
  assert_no_shell_errors "$OUT"
  assert_contains "$OUT" "EDITOR=code VISUAL=code"
}

test_kit_sets_tokyo_night_fzf_colors() {
  local home; home=$(new_home)
  run_kit "$home" 'print -r -- "$FZF_DEFAULT_OPTS"; print -r -- "$FZF_DEFAULT_COMMAND"'
  assert_contains "$OUT" "bg:#24283b"
  assert_contains "$OUT" "fd --hidden --strip-cwd-prefix --exclude .git"
}

test_kit_is_silent_when_tools_are_missing() {
  local home; home=$(new_home)
  run_kit "$home" '(( $+aliases[ll] )) || print -r -- NO-LL; (( $+functions[rgf] )) && print -r -- HAS-RGF' \
    PATH=/usr/bin:/bin HOMEBREW_PREFIX=/nonexistent
  assert_contains "$OUT" "KIT-DONE"
  assert_no_shell_errors "$OUT"
  assert_contains "$OUT" "NO-LL"
  assert_contains "$OUT" "HAS-RGF"
}

test_kit_leaves_no_helper_variables() {
  local home; home=$(new_home)
  run_kit "$home" '(( ${+_mt_brew} )) && print -r -- LEAKED'
  assert_no_shell_errors "$OUT"
  assert_not_contains "$OUT" "LEAKED"
}

test_kit_is_silent_with_old_fzf_without_zsh_flag() {
  local home bin; home=$(new_home); bin="$home.bin"
  mkdir -p "$bin"
  # fzf before 0.48 has no --zsh option.
  printf '#!/bin/sh\necho "unknown option: $1" >&2\nexit 2\n' > "$bin/fzf"
  chmod +x "$bin/fzf"
  run_kit "$home" 'true' PATH="$bin:$PATH"
  assert_contains "$OUT" "KIT-DONE"
  assert_no_shell_errors "$OUT"
  assert_not_contains "$OUT" "unknown option"
}
