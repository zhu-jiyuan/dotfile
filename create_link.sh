create_symlinks() {
	src="$1"
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

# 传入一个目录，和指定的目标目录，把该目录下的所有文件和目录创建软链接到目标目录
create_symlinks_to_target() {
	src_dir="$1"
	target_dir="$2"
	# echo "[DEBUG]: Creating symlinks from $src_dir to $target_dir"

	if [ ! -d "$src_dir" ]; then
		echo "[ERROR]: Source directory $src_dir does not exist."
		return 1
	fi
	if [ ! -d "$target_dir" ]; then
		echo "[INFO]: Target directory $target_dir does not exist. Creating it."
		mkdir -p "$target_dir"
	fi
	for file in "$src_dir"/*; do
		if [ -d "$file" ]; then
			create_symlinks_to_target "$file" "$target_dir/$(basename "$file")"
		elif [ -f "$file" ]; then
			create_symlinks "$file" "$target_dir/$(basename "$file")"
		fi
	done
}

config_dir="$HOME/.config"
# check config directory exists
if [ ! -d "$config_dir" ]; then
	echo "[INFO]: $config_dir does not exist. Creating it."
	mkdir -p "$config_dir"
fi

local_bin_dir="$HOME/.local/bin"
if [ ! -d "$local_bin_dir" ]; then
	echo "[INFO]: $local_bin_dir does not exist. Creating it."
	mkdir -p "$local_bin_dir"
fi

create_symlinks "$PWD/git/.gitconfig" "$HOME/.gitconfig"
create_symlinks "$PWD/yazi" "$config_dir/yazi"
create_symlinks "$PWD/tmux" "$config_dir/tmux"
create_symlinks "$PWD/rofi" "$config_dir/rofi"
create_symlinks "$PWD/zsh" "$config_dir/zsh"
create_symlinks "$PWD/zsh/.zshrc" "$HOME/.zshrc"
create_symlinks "$PWD/nvim" "$config_dir/nvim"
create_symlinks "$PWD/lazygit" "$config_dir/lazygit"
create_symlinks "$PWD/kitty" "$config_dir/kitty"
create_symlinks "$PWD/i3" "$config_dir/i3"
create_symlinks "$PWD/i3status" "$config_dir/i3status"
create_symlinks "$PWD/dunst" "$config_dir/dunst"
create_symlinks "$PWD/.Xmodmap" "$HOME/.Xmodmap"
create_symlinks "$PWD/ghostty" "$config_dir/ghostty"
create_symlinks "$PWD/waybar" "$config_dir/waybar"
create_symlinks "$PWD/fastfetch" "$config_dir/fastfetch"
create_symlinks "$PWD/hypr" "$config_dir/hypr"
create_symlinks "$PWD/niri" "$config_dir/niri"
create_symlinks "$PWD/mako" "$config_dir/mako"
create_symlinks "$PWD/fcitx5" "$config_dir/fcitx5"
create_symlinks "$PWD/tmux-sessionizer" "$config_dir/tmux-sessionizer"
create_symlinks "$PWD/emacs" "$config_dir/emacs"

create_symlinks_to_target "$PWD/local" "$HOME/.local"
