# dotfile

Personal configs, symlinked into `~/.config` and `$HOME`.

## Install

```shell
git clone <repo-url> ~/dotfile
cd ~/dotfile
git submodule update --init --recursive

# link configs (must run from the repo root)
bash install.sh

# install CLI tools listed in mise/config.toml
mise install
```

Then start `tmux` and press `prefix + I` to install plugins.

`install.sh` never overwrites a real file or directory: if a target
already exists, move it aside and run the script again.

`git/.gitconfig` is copied (not linked) to `~/.gitconfig`, and only when
`~/.gitconfig` does not exist yet, so local edits stay out of the repo.

## Tools

CLI tools are managed by [mise](https://mise.jdx.dev); add them to
`mise/config.toml` (linked to `~/.config/mise`).

## Notebook look

[Notebook](claude/plugins/notebook/README.md) turns Claude Code, desktop and
terminal, into ruled notebook paper: sticky-note messages, a hand-drawn
critter on each row, and a "this page" pane with tallies, the to-do list and
a pencil for context left. Install it from this repository root:

```bash
claude plugin install notebook --marketplace ./claude/plugins --scope user
```

Ghostty uses the same paper through its "Notebook Paper" theme
(`ghostty/themes/`) and rules every window: a shader
(`ghostty/shaders/notebook-rules.glsl`) reads the row height off the cursor, so
the lines follow any font size, and `ghostty/notebook-paper.png` adds the red
margin.

## Font

The terminal configs use JetBrains Mono Nerd Font.

```shell
# macOS
brew install --cask font-jetbrains-mono-nerd-font

# Linux
sh install_font.sh
```
