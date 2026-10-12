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
  run_kit "$home" '(( $+aliases[ll] )) || print -r -- NO-LL; (( $+functions[rgf] || $+functions[ff] )) || print -r -- NO-RGF-FF' \
    PATH=/usr/bin:/bin HOMEBREW_PREFIX=/nonexistent
  assert_contains "$OUT" "KIT-DONE"
  assert_no_shell_errors "$OUT"
  assert_contains "$OUT" "NO-LL"
  assert_contains "$OUT" "NO-RGF-FF"
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

test_kit_keeps_existing_aliases() {
  local home; home=$(new_home)
  KIT_BEFORE="alias ll='ls -l'; alias lg=mygit" run_kit "$home" 'alias ll; alias lg; alias la'
  assert_no_shell_errors "$OUT"
  assert_contains "$OUT" "ll='ls -l'"
  assert_contains "$OUT" "lg=mygit"
  assert_contains "$OUT" "la='eza -la --icons --group-directories-first --git'"
}

test_kit_keeps_existing_fzf_settings() {
  local home; home=$(new_home)
  run_kit "$home" 'print -r -- "OPTS=$FZF_DEFAULT_OPTS CMD=$FZF_DEFAULT_COMMAND"' \
    FZF_DEFAULT_OPTS=--mine FZF_DEFAULT_COMMAND=mycmd
  assert_no_shell_errors "$OUT"
  assert_contains "$OUT" "OPTS=--mine CMD=mycmd"
}

test_kit_uses_starship_prompt_by_default() {
  local home; home=$(new_home)
  run_kit "$home" 'print -r -- "PROMPT=$PROMPT"'
  assert_contains "$OUT" "starship prompt --terminal-width"
}

test_kit_keeps_oh_my_zsh_theme_prompt() {
  local home; home=$(new_home)
  KIT_BEFORE="ZSH_THEME=robbyrussell; PROMPT=MY-PROMPT" run_kit "$home" 'print -r -- "PROMPT=$PROMPT"'
  assert_no_shell_errors "$OUT"
  assert_contains "$OUT" "PROMPT=MY-PROMPT"
}

test_kit_keeps_powerlevel10k_prompt() {
  local home; home=$(new_home)
  KIT_BEFORE="p10k() { :; }; PROMPT=MY-PROMPT" run_kit "$home" 'print -r -- "PROMPT=$PROMPT"'
  assert_no_shell_errors "$OUT"
  assert_contains "$OUT" "PROMPT=MY-PROMPT"
}

# fake_pickers <dir>: an fzf that "picks" $FAKE_PICK, and editors that log their arguments
# to <dir>/editor.log. rg and fd are the real ones.
fake_pickers() {
  local name
  mkdir -p "$1"
  printf '#!/bin/sh\n[ "$1" = --zsh ] && exit 2\nprintf "%%s\\n" "$FAKE_PICK"\n' > "$1/fzf"
  for name in hx nvim code myed; do
    printf '#!/bin/sh\necho "$(basename "$0") $*" >> "$(dirname "$0")/editor.log"\n' > "$1/$name"
  done
  chmod +x "$1"/*
}

# open_with <editor> <command>: runs <command> (rgf or ff) with EDITOR=<editor>
# and sets LOG to what the editor was called with.
open_with() {
  local home bin; home=$(new_home); bin="$home.bin"
  fake_pickers "$bin"
  run_kit "$home" "$2" PATH="$bin:$PATH" EDITOR="$1" FAKE_PICK="src/app.py:12:5:match"
  assert_no_shell_errors "$OUT"
  LOG=$(cat "$bin/editor.log" 2>/dev/null)
}

test_rgf_opens_helix_at_line() {
  open_with hx rgf
  assert_eq "$LOG" "hx src/app.py:12"
}

test_rgf_opens_vim_style_editor_at_line() {
  open_with nvim rgf
  assert_eq "$LOG" "nvim +12 src/app.py"
}

test_rgf_opens_vscode_at_line_with_editor_flags() {
  open_with "code --wait" rgf
  assert_eq "$LOG" "code --wait -g src/app.py:12"
}

test_rgf_opens_unknown_editor_without_line() {
  open_with myed rgf
  assert_eq "$LOG" "myed src/app.py"
}

test_ff_opens_file_in_editor() {
  open_with nvim 'FAKE_PICK=src/app.py ff'
  assert_eq "$LOG" "nvim src/app.py"
}
