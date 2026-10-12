# modern-terminal: shell setup, loaded from ~/.zshrc by install.sh.
# Every tool is optional: anything that isn't installed is skipped silently.
# Aliases, fzf settings and a prompt you set earlier in ~/.zshrc are kept.
# Put your own settings after the loader line in ~/.zshrc to override the rest.

# Homebrew prefix: /opt/homebrew on Apple silicon, /usr/local on Intel.
_mt_brew="${HOMEBREW_PREFIX:-}"
if [[ -z "$_mt_brew" ]] && (( $+commands[brew] )); then
  _mt_brew="$(brew --prefix)"
fi

# --- Plugins ---
if [[ -r "$_mt_brew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$_mt_brew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# --- Prompt and navigation ---
# Keep a prompt you already have: an Oh My Zsh theme, Powerlevel10k, or starship itself.
if (( $+commands[starship] )) && [[ -z "${ZSH_THEME:-}" ]] &&
   (( ! $+functions[p10k] && ! $+functions[prompt_starship_precmd] )); then
  eval "$(starship init zsh)"
fi
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# --- fzf: Ctrl+R history, Ctrl+T files, Alt+C directories (TokyoNight Storm + fd) ---
if (( $+commands[fzf] )); then
  # fzf before 0.48 has no --zsh: skip the key bindings rather than print an error.
  _mt_fzf_init="$(fzf --zsh 2>/dev/null)" && eval "$_mt_fzf_init"
  unset _mt_fzf_init
  # Each setting is only filled in if you haven't set it yourself.
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND="${FZF_DEFAULT_COMMAND:-fd --hidden --strip-cwd-prefix --exclude .git}"
    export FZF_CTRL_T_COMMAND="${FZF_CTRL_T_COMMAND:-$FZF_DEFAULT_COMMAND}"
    export FZF_ALT_C_COMMAND="${FZF_ALT_C_COMMAND:-fd --type d --hidden --strip-cwd-prefix --exclude .git}"
  fi
  if [[ -z "${FZF_DEFAULT_OPTS:-}" ]]; then
    export FZF_DEFAULT_OPTS="
    --color=bg+:#292e42,bg:#24283b,spinner:#bb9af7,hl:#7aa2f7
    --color=fg:#c0caf5,header:#7aa2f7,info:#7dcfff,pointer:#bb9af7
    --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7dcfff,hl+:#7aa2f7
    --color=border:#565f89
    --height=60% --layout=reverse --border --margin=1 --padding=1"
  fi
fi

# --- Aliases ---
# `ls` stays the real command so scripts and agents get standard output.
# _mt_alias <name> <command>: defines the alias unless you already have one by that name.
_mt_alias() { (( $+aliases[$1] )) || alias "$1=$2"; }
if (( $+commands[eza] )); then
  _mt_alias ll "eza -l --icons --group-directories-first --git"
  _mt_alias la "eza -la --icons --group-directories-first --git"
  _mt_alias lt "eza --tree --level=2 --icons --group-directories-first"
  _mt_alias tree "eza --tree --icons"
fi
(( $+commands[bat] )) && _mt_alias bcat "bat --paging=never"
(( $+commands[lazygit] )) && _mt_alias lg "lazygit"
(( $+commands[glow] )) && _mt_alias glow "glow -t"   # open in TUI mode by default
# Ghostty's CLI lives inside the app bundle.
[[ -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]] && _mt_alias ghostty "/Applications/Ghostty.app/Contents/MacOS/ghostty"
unfunction _mt_alias

# --- Editors: Helix by default, unless you already chose one ---
if (( $+commands[hx] )); then
  export EDITOR="${EDITOR:-hx}"
  export VISUAL="${VISUAL:-hx}"
fi
export MICRO_TRUECOLOR=1

# _mt_edit <file> [line]: opens <file> in $EDITOR, at <line> for editors that support it.
# $EDITOR may include flags, for example "code --wait".
_mt_edit() {
  local -a editor=(${(z)${EDITOR:-vi}})
  if [[ -z "${2:-}" ]]; then
    "${editor[@]}" "$1"
    return
  fi
  case "${editor[1]:t}" in
    hx|helix|micro|zed|subl) "${editor[@]}" "$1:$2" ;;
    vi|vim|nvim|nano|emacs|emacsclient|kak) "${editor[@]}" "+$2" "$1" ;;
    code|code-insiders|cursor|windsurf) "${editor[@]}" -g "$1:$2" ;;
    *) "${editor[@]}" "$1" ;;
  esac
}

# --- rgf: live ripgrep -> bat preview -> open in $EDITOR at the matched line ---
# ' | ' (spaces around the pipe) is normalized to '|' so fzf-style OR works here too.
# Trade-off: you can no longer grep for a literal space-padded pipe (e.g. 'a | b').
if (( $+commands[fzf] && $+commands[rg] )); then
  rgf() {
    local rg_prefix="rg --column --line-number --no-heading --color=always --smart-case"
    local strip='s/[[:space:]]*|[[:space:]]*/|/g'
    local initial; initial=$(printf %s "${*:-}" | sed "$strip")
    local out
    out=$(
      FZF_DEFAULT_COMMAND="$rg_prefix $(printf %q "$initial")" \
      fzf --ansi --disabled --query "$initial" \
          --bind "change:reload:sleep 0.05; $rg_prefix \"\$(printf %s {q} | sed '$strip')\" || true" \
          --delimiter : \
          --preview 'bat --color=always {1} --highlight-line {2} --style=numbers' \
          --preview-window 'right,60%,+{2}+3/3,~3'
    ) || return
    local file line
    file=$(printf '%s' "$out" | cut -d: -f1)
    line=$(printf '%s' "$out" | cut -d: -f2)
    [ -n "$file" ] && _mt_edit "$file" "$line"
  }
fi

# --- ff: fuzzy-find a file by NAME (cwd and below) -> open in $EDITOR ---
if (( $+commands[fzf] && $+commands[fd] )); then
  ff() {
    local file
    file=$(
      fd --type f --hidden --strip-cwd-prefix --exclude .git "${1:-}" \
      | fzf --ansi --query "${1:-}" \
            --preview 'bat --color=always --style=numbers {}' \
            --preview-window 'right,60%'
    ) || return
    [ -n "$file" ] && _mt_edit "$file"
  }
fi

# Syntax highlighting goes last so it can wrap every widget defined above.
if [[ -r "$_mt_brew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$_mt_brew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

unset _mt_brew
