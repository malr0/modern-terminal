# modern-terminal

A starter kit for a modern macOS terminal: Ghostty, zsh with starship, fzf and zoxide,
fast modern command-line tools, and one Tokyo Night Storm theme across all of them.

![The starship prompt and an eza listing with icons and git status](docs/screenshots/ll.png)

**Prompt and `ll`.** The default zsh prompt is a plain `user@host ~ %`. The starship
prompt shows the current folder, the git branch and its status, and the time.
`ll` replaces `ls -l`: folders first, an icon for each file type, short sizes such as
`7.6k`, and a git column that marks new and modified files.

<a href="docs/screenshots/delta.png"><img src="docs/screenshots/delta.png" width="559" alt="A side-by-side git diff in delta with syntax highlighting"></a>

**`git diff` with delta.** Plain `git diff` prints a single column of whole lines in red
and green. With delta you see the old and new file side by side, with line numbers,
syntax highlighting and the changed words marked inside each line. Click the image to
see it full size.

## What you get

| Area | Tools |
|---|---|
| Terminal | Ghostty, JetBrains Mono Nerd Font |
| Shell | zsh with the starship prompt, autosuggestions, syntax highlighting, fzf, zoxide |
| Search and view | ripgrep (`rg`), fd, bat, eza, glow, jq, sd, ast-grep (`sg`) |
| Git | lazygit, delta, gh |
| Editors | Helix (`hx`), micro |
| System | btop |

The [cheat sheet](docs/cheatsheet.md) lists the commands and shortcuts.
[AI coding agents](docs/agents.md) describes agents that fit this setup.

## Requirements

- macOS
- [Homebrew](https://brew.sh)
- zsh (the default shell on macOS)

## Install

```sh
git clone https://github.com/malr0/modern-terminal.git ~/modern-terminal
~/modern-terminal/install.sh
```

Then open Ghostty from Applications. Your other terminals pick up the shell setup in
any new window.

Keep the cloned folder: your shell loads the kit from it. To update:

```sh
git -C ~/modern-terminal pull
```

## What the installer changes

It adds to your setup and never overwrites a file, so running it again is safe.

1. Installs the tools in the [Brewfile](Brewfile) with `brew bundle --no-upgrade`.
   Tools you already have stay at their current version. If one misbehaves with the
   kit's config, update it with `brew upgrade <name>`. If Ghostty or JetBrains Mono
   Nerd Font is already installed outside Homebrew, the installer skips it.
2. Adds two lines to the end of `~/.zshrc`:
   ```sh
   # modern-terminal
   source "/Users/you/modern-terminal/zsh/kit.zsh"
   ```
   The kit keeps aliases, `FZF_*` settings and a prompt you set earlier in `~/.zshrc`.
   Anything you put after these lines overrides the kit.
3. Adds [git/delta.gitconfig](git/delta.gitconfig) to your global git config with
   `include.path`, so `git diff`, `git log -p` and lazygit use delta. Your name, email
   and other git settings are not touched. If your git config already sets a pager,
   `interactive.diffFilter`, `merge.conflictStyle` or any `delta.*` option, the installer
   leaves git alone and says so, since the include would override them.
4. Copies the Tokyo Night configs from [config/](config) for each tool, **only where you
   don't have that file yet**. `XDG_CONFIG_HOME` is respected if you've set it. The summary at the end lists what was `installed` and
   what was `skipped (exists)`.

`kit.zsh` sets `EDITOR` to Helix only if you haven't set an editor yourself.
`rgf` and `ff` open files in `$EDITOR`.

## Oh My Zsh and other prompt setups

If you use an Oh My Zsh theme or Powerlevel10k, the kit keeps your prompt and doesn't
start starship. To switch to starship, set `ZSH_THEME=""` or remove Powerlevel10k.
With Prezto you may see two prompts: turn off its prompt module to use starship.

If Oh My Zsh also loads `zsh-autosuggestions` or `zsh-syntax-highlighting`, remove them
from your `plugins=(...)` list so they don't load twice.

## Uninstall

1. Delete the `# modern-terminal` line from `~/.zshrc`, and the
   `source ".../zsh/kit.zsh"` line below it.
2. Remove the git include, wherever you cloned the kit:
   ```sh
   git config --global --unset-all include.path '/git/delta\.gitconfig$'
   ```
3. Delete any copied config files you don't want. The install summary lists them.
4. Remove tools you don't want with `brew uninstall <name>`.
5. Delete the cloned folder (`~/modern-terminal` if you followed the install steps).

## Credits and licence

The kit is released under the [MIT licence](LICENSE).

The Tokyo Night colours come from [tokyonight.nvim](https://github.com/folke/tokyonight.nvim)
by Folke Lemaitre. The bat theme is taken from that project and is covered by its
[Apache-2.0 licence](config/bat/themes/LICENSE-tokyonight.txt).
