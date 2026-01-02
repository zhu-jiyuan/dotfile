
mkdir -p ~/downloads
cd ~/downloads
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
mkdir -p ~/.local/share/fonts/
unzip JetBrainsMono.zip -d ~/.local/share/fonts/jetbrains-mono
fc-cache -f -v

