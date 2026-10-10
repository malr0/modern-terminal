# Cheat sheet

`Alt` is the left Option key. The kit's Ghostty config makes it work as Alt.

## Moving around

| Keys / command | What it does |
|---|---|
| `z proj` | Jump to the most used directory matching "proj" (zoxide) |
| `zi` | Pick a directory interactively |
| `Alt+C` | Fuzzy-find a subdirectory and cd into it |
| `ll` / `la` | List files with icons and git status (`la` includes hidden files) |
| `lt` / `tree` | Tree view (two levels / full) |

## Finding things

| Keys / command | What it does |
|---|---|
| `Ctrl+R` | Fuzzy-search your shell history |
| `Ctrl+T` | Fuzzy-find a file and insert its path |
| `ff [name]` | Fuzzy-find a file by name, preview it, open it in Helix |
| `rgf [text]` | Live search file contents, preview the match, open Helix at that line |
| `rg text` | Search file contents (respects .gitignore) |
| `fd name` | Find files by name |
| `sd 'old' 'new' file` | Find and replace in files |
| `sg --pattern 'console.log($A)' --lang js` | Search code by structure (ast-grep) |

## Reading

| Command | What it does |
|---|---|
| `bat file` | View a file with syntax highlighting and git changes |
| `bcat file` | Same, without the pager |
| `glow` | Browse the Markdown files in this directory |
| `glow README.md` | Read one Markdown file |
| `jq '.items[].name' data.json` | Query JSON |

## Git

| Command | What it does |
|---|---|
| `lg` | lazygit: stage hunks, commit, rebase, browse history |
| `git diff`, `git log -p` | Side-by-side diffs through delta (`n`/`N` jumps between files) |
| `gh pr list`, `gh pr checkout 123` | Work with GitHub pull requests |

## Editing

| Keys / command | What it does |
|---|---|
| `hx file` | Helix. `i` to insert, `Esc` back to normal mode, `Ctrl+S` save, `:q` quit |
| `Space f` (in Helix) | File picker |
| `micro file` | Simple editor with familiar keys (`Ctrl+S`, `Ctrl+Q`) |

## System

| Command | What it does |
|---|---|
| `btop` | CPU, memory, disk and processes |

## Ghostty

| Keys | What it does |
|---|---|
| `Cmd+T` | New tab |
| `Cmd+D` / `Cmd+Shift+D` | Split right / split down |
| `Cmd+Shift+,` | Reload the config |
