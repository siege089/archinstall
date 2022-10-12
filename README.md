# archinstall
The goal of this project is to provide a solid base for customized installations of arch for personal use as opposed to other arch installers like the default [archinstall](https://wiki.archlinux.org/title/archinstall) that is designed to work for anyone.

The base installation makes some sensible default choices from the [Installation Guide](https://wiki.archlinux.org/title/Installation_guide) such as btrfs, efi boot, systemd-boot, etc.

## Usage

```bash
pacman -Sy git
git clone https://github.com/siege089/archinstall.git
cd archinstall
python archinstall.py
```