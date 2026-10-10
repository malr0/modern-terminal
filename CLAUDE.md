# CLAUDE.md

Guidance for agents working in this repo.

## What this is

`modern-terminal` is a public starter kit that installs a "modern terminal" setup on
macOS: Ghostty, zsh with starship/fzf/zoxide, modern CLI tools (rg, fd, bat, eza, glow,
jq, sd, ast-grep, delta, lazygit, gh, btop), Helix/micro, all themed Tokyo Night Storm.
It is written for the author's colleagues, who install it with `git clone` +
`./install.sh`. The author also uses it daily: their own `~/.zshrc` loads `zsh/kit.zsh`
from this clone.

## Layout

| Path | What it is |
|---|---|
| `Brewfile` | Core tools only. No agents (Claude Code, Codex) and no herdr |
| `install.sh` | Installer: preflight → `brew bundle` → loader line in `~/.zshrc` → git `include.path` for `git/delta.gitconfig` → copy configs where missing → summary |
| `zsh/kit.zsh` | Shell setup sourced from `~/.zshrc`. Every tool is optional |
| `git/delta.gitconfig` | delta pager and colours, added with `include.path` |
| `config/` | Tool configs copied to the user's machine (copies of the author's own configs) |
| `docs/cheatsheet.md`, `docs/agents.md` | User docs. `agents.md` links to official install docs only, no install commands |
| `tests/` | Bash test suite (see Testing) |

## Rules the code must keep

- **macOS + Homebrew only.** No Linux/WSL paths.
- **`install.sh` runs under macOS `/bin/bash` 3.2.** No associative arrays, no `mapfile`,
  no `${var,,}`, and no possibly-empty array expansion under `set -u`.
- **Never overwrite a file, and stay idempotent.** A second run must change nothing
  (there's a test for that). Configs are copied only where no file exists.
- **Leave the user's git config alone.** The kit never touches `[user]`, and skips the
  delta include if the user already sets `core.pager`, `interactive.diffFilter`,
  `merge.conflictStyle` or any `delta.*` option.
- **Respect `XDG_CONFIG_HOME`** for bat, helix, micro, btop, Ghostty and lazygit.
  starship and glow use fixed paths on macOS.
- **No personal data in shipped files:** no `/Users/<name>` paths, no work email or work
  domain. `config/glow/glow.yml` uses a `__HOME__` token that `install.sh` replaces.
- **`kit.zsh` must load silently** when tools are missing or Homebrew is at `/usr/local`.

## Testing

```sh
tests/run.sh            # all tests
tests/run.sh install    # only tests whose name contains "install"
shellcheck -x install.sh tests/run.sh tests/lib.sh tests/test_*.sh
```

- The tests run `install.sh --skip-brew` with `/bin/bash` against throwaway `HOME`
  directories, so they never touch the real home folder. Helpers live in `tests/lib.sh`:
  `run_install`, `run_kit` (interactive zsh on a pseudo-terminal), `snapshot`,
  `copy_repo` and assertions.
- Work test-first: write the failing test, watch it fail, then fix.
- Don't run `install.sh` against the real `HOME` without asking. On the author's Mac it
  is already installed.

## Git workflow

- **Never commit on `main`.** Make a branch per change, push it, and open a PR with
  `gh pr create`. The author reviews and squash-merges.
- Commit as `mattias@malro.se` (already set in this repo's local git config). No work
  email anywhere.
- No `Co-Authored-By` trailers in commits and no "Generated with Claude Code" line in
  PRs.
- `gh` can push and open PRs, but can't create repos (the token lacks that permission).

## Local-only files (git-ignored)

- `TODO.md`: remaining work. Read it first.
- `docs/superpowers/`: the original design spec and implementation plan. Useful
  background on why things are the way they are. Kept out of the public repo on purpose.
- `.superpowers/`: scratch space for the planning tools.

## Handover (2026-10-10)

- PR #1 (the whole kit) is merged into `main`. Branch `initial-kit` is merged and can
  be deleted.
- The author's Mac runs the kit. Backups from before the switch are
  `~/.zshrc.before-modern-terminal` and `~/.gitconfig.before-modern-terminal`.
- The author's `~/.zshrc` sources `zsh/kit.zsh` from **this working tree**, so whatever
  branch is checked out here is what their new terminals load. A broken `kit.zsh`
  breaks their shell. Run `tests/run.sh kit` before leaving a branch checked out.
- Still open (details in `TODO.md`): a clean-machine test on the author's second Mac
  (an M1), a README screenshot, and minor installer, shell and README fixes from the
  code review.
- When the author changes one of their own tool configs, sync the copy in `config/`.
  For example, lazygit 0.66 migrated `git.pagers` to `git.diffRenderers` and the kit's
  copy was updated to match.
