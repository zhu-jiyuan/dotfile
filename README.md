# INSTALL

Bash can use it, maybe.
I like zsh, btw.

```shell
./install_dependencies.sh

zsh install.sh

# wait a minute

# tmux init
tmux
# push prefix + I


```

## Dependencies

`install_dependencies.sh` installs Debian/Ubuntu packages from
`packages/debian.list`. It checks both dpkg package status and existing command
names, so locally installed tools such as `nvim`, `niri`, or `ghostty` are not
installed again from apt.

```shell
./install_dependencies.sh --dry-run
./install_dependencies.sh
```

Tools that are not in the default Debian apt repositories are listed in
`packages/manual.list`; the script reports missing ones after the apt pass.
