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

## Font

The terminal configs use JetBrains Mono Nerd Font.

```shell
# macOS
brew install --cask font-jetbrains-mono-nerd-font

# Linux
sh install_font.sh
```
