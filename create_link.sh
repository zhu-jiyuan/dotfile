create_symlinks() {
	src="$PWD/$1"
	target="$2"

	if [ -L "$target" ]; then
		current_link=$(readlink "$target")
		if [ "$current_link" = "$src" ]; then
			echo "[INFO]: $target link already exist."
			return 0
		else
			echo "[WARNING]: rm link: $target, current_link=$current_link"
			rm "$target"  # 删除旧的软链接
		fi
	fi

    if [ -e "$target" ]; then
		echo "[NOTIFY]: $target already exists. Please remove it first."
		return 1
    fi

	ln -s "$src" "$target"
	echo "[SUCCESS]: $target -> $src"
}

config_dir="$HOME/.config"

create_symlinks "git/.gitconfig" "$HOME/.gitconfig"
create_symlinks "yazi" "$config_dir/yazi"
create_symlinks "tmux" "$config_dir/tmux"
create_symlinks "rofi" "$config_dir/rofi"
create_symlinks "zsh" "$config_dir/zsh"
create_symlinks "zsh/.zshrc" "$HOME/.zshrc"
create_symlinks "nvim" "$config_dir/nvim"
create_symlinks "lazygit" "$config_dir/lazygit"
create_symlinks "kitty" "$config_dir/kitty"
create_symlinks "i3" "$config_dir/i3"
create_symlinks "i3status" "$config_dir/i3status"
create_symlinks "dunst" "$config_dir/dunst"
create_symlinks ".Xmodmap" "$HOME/.Xmodmap"
create_symlinks "ghostty" "$config_dir/ghostty"
