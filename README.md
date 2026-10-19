# dotfile

Personal configs, symlinked into `~/.config` and `$HOME`.

## Install

```shell
git clone <repo-url> ~/dotfile
cd ~/dotfile
git submodule update --init --recursive

# link configs (must run from the repo root)
bash create_link.sh

# install CLI tools listed in mise/config.toml
mise install
```

Then start `tmux` and press `prefix + I` to install plugins.

`create_link.sh` never overwrites a real file or directory: if a target
already exists, move it aside and run the script again.

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
