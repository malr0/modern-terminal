# modern-terminal: shell setup, loaded from ~/.zshrc by install.sh.
# Every tool is optional: anything that isn't installed is skipped silently.
# Put your own settings after the loader line in ~/.zshrc to override these.

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
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# --- fzf: Ctrl+R history, Ctrl+T files, Alt+C directories (TokyoNight Storm + fd) ---
if (( $+commands[fzf] )); then
  # fzf before 0.48 has no --zsh: skip the key bindings rather than print an error.
  _mt_fzf_init="$(fzf --zsh 2>/dev/null)" && eval "$_mt_fzf_init"
  unset _mt_fzf_init
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git'
  fi
  export FZF_DEFAULT_OPTS="
    --color=bg+:#292e42,bg:#24283b,spinner:#bb9af7,hl:#7aa2f7
    --color=fg:#c0caf5,header:#7aa2f7,info:#7dcfff,pointer:#bb9af7
    --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7dcfff,hl+:#7aa2f7
    --color=border:#565f89
    --height=60% --layout=reverse --border --margin=1 --padding=1"
fi

# --- Aliases ---
# `ls` stays the real command so scripts and agents get standard output.
if (( $+commands[eza] )); then
  alias ll="eza -l --icons --group-directories-first --git"
  alias la="eza -la --icons --group-directories-first --git"
  alias lt="eza --tree --level=2 --icons --group-directories-first"
  alias tree="eza --tree --icons"
fi
(( $+commands[bat] )) && alias bcat="bat --paging=never"
(( $+commands[lazygit] )) && alias lg="lazygit"
(( $+commands[glow] )) && alias glow="glow -t"   # open in TUI mode by default
# Ghostty's CLI lives inside the app bundle.
[[ -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]] && alias ghostty="/Applications/Ghostty.app/Contents/MacOS/ghostty"

# --- Editors: Helix by default, unless you already chose one ---
if (( $+commands[hx] )); then
  export EDITOR="${EDITOR:-hx}"
  export VISUAL="${VISUAL:-hx}"
fi
export MICRO_TRUECOLOR=1

# --- rgf: live ripgrep -> bat preview -> open in Helix at the matched line ---
# ' | ' (spaces around the pipe) is normalized to '|' so fzf-style OR works here too.
# Trade-off: you can no longer grep for a literal space-padded pipe (e.g. 'a | b').
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
  [ -n "$file" ] && hx "$file:$line"
}

# --- ff: fuzzy-find a file by NAME (cwd and below) -> open in Helix ---
ff() {
  local file
  file=$(
    fd --type f --hidden --strip-cwd-prefix --exclude .git "${1:-}" \
    | fzf --ansi --query "${1:-}" \
          --preview 'bat --color=always --style=numbers {}' \
          --preview-window 'right,60%'
  ) || return
  [ -n "$file" ] && hx "$file"
}

# Syntax highlighting goes last so it can wrap every widget defined above.
if [[ -r "$_mt_brew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$_mt_brew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

unset _mt_brew
