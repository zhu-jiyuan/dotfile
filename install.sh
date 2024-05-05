#!/usr/bin/env zsh

depencies=(zsh git fzf zoxide batcat)

is_exist (){
    if [ -x "$(command -v $1)" ]; then
        # echo "$1 is installed."
        return true
    else
        echo "$1 is not installed. Please install $1 first."
        exit 1
    fi 
}

# check depencies
for dep in $depencies; do
    is_exist $dep 
done

######### START INSTALL #########

# cd to the directory of this script
cd $(dirname $0)

git submodule update --init --recursive

# you can write your own config in .zsh_custom

[[ ! ( -f $HOME/.zshrc && ! -h $HOME/.zshrc) ]] || mv $HOME/.zshrc $HOME/.zshrc.bak
ln -s $(pwd)/zsh/.zshrc ~/.zshrc

cp ./tmux-sessionizer ~/.local/bin/
