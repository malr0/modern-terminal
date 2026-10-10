# AI coding agents in the terminal

The kit doesn't install any agents. Each one needs its own account or subscription, and
your company may have rules about which AI tools you can use, so check those first.

## The tools

**[herdr](https://herdr.dev)** is a terminal multiplexer built for coding agents. Run
several agents side by side in panes and tabs and switch between them.

**[Claude Code](https://code.claude.com/docs/en/setup)** is Anthropic's coding agent. It
reads your repo, edits files and runs commands in the terminal. It needs a Claude plan
or an Anthropic API account.

**[Codex](https://developers.openai.com/codex/cli)** is OpenAI's coding agent for the
terminal. It needs a ChatGPT plan or an OpenAI API account.

## Installing

Use the install method each tool's own documentation recommends (linked above). Some of
them are also packaged elsewhere, for example in Homebrew, but the official instructions
are the ones to follow.

## How they fit with the kit

- Run agents in herdr panes, on the same task to compare them or on different repos.
- Agents write plans and notes as Markdown. Read them with `glow` in another pane.
- Review what an agent changed with `lg` or `git diff`.
- Agents use `rg`, `fd` and `jq` too when they're installed, which makes them faster.
