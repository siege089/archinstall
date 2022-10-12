echo "Install yay"
cd /opt
sudo git clone https://aur.archlinux.org/yay-git.git
sudo chown -R $(id -u):$(id -g) ./yay-git
cd yay-git
makepkg -si

yay -S btrfs-assistant tabby timeshift
