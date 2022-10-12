#!/bin/bash

echo "starting script" | tee arch-install.log
error_exit()
{
	echo "Error: $1"
	exit 1
}




echo "3.1 Fstab"
genfstab -U /mnt >> /mnt/etc/fstab


archroot () {
	root=$1
	hostname=$2
	cpu=$3
	username=$4

	echo "3.3 Time zone"
	ln -sf /usr/share/zoneinfo/US/Pacific /etc/localtime
	hwclock --systohc

	echo "3.4 Localization"
	sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf

	echo "3.5 Network configuration"
	echo "$hostname" > /etc/hostname

	echo "3.7 Root password"
	passwd root

	echo "3.8 Boot loader"

	if [[ "$cpu" = "amd" ]]
	then
		yes | pacman -S amd-ucode
	fi
	if [[ "$cpu" = "intel" ]]
	then
		yes | pacman -S intel-ucode
	fi


	bootctl install --esp-path=/boot
	echo "title Arch Linux Zen" > /boot/loader/entries/arch-zen.conf
	echo "linux /vmlinuz-linux-zen" >> /boot/loader/entries/arch-zen.conf
	if [[ "$cpu" = "amd" ]]
	then
		echo "initrd /amd-ucode.img" >> /boot/loader/entries/arch-zen.conf
	fi
	if [[ "$cpu" = "intel" ]]
	then
		echo "initrd /intel-ucode.img" >> /boot/loader/entries/arch-zen.conf
	fi
	echo "initrd /initramfs-linux-zen.img" >> /boot/loader/entries/arch-zen.conf
	echo "options root=$root rw" >> /boot/loader/entries/arch-zen.conf

	echo "title Arch Linux Zen (fallback initramfs)" > /boot/loader/entries/arch-zen-fallback.conf
	echo "linux /vmlinuz-linux-zen" >> /boot/loader/entries/arch-zen-fallback.conf
	if [[ "$cpu" = "amd" ]]
	then
		echo "initrd /amd-ucode.img" >> /boot/loader/entries/arch-zen-fallback.conf
	fi
	if [[ "$cpu" = "intel" ]]
	then
		echo "initrd /intel-ucode.img" >> /boot/loader/entries/arch-zen-fallback.conf
	fi
	echo "initrd /initramfs-linux-zen-fallback.img" >> /boot/loader/entries/arch-zen-fallback.conf
	echo "options root=$root rw" >> /boot/loader/entries/arch-zen-fallback.conf

	echo "title Arch Linux" > /boot/loader/entries/arch.conf
	echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf
	if [[ "$cpu" = "amd" ]]
	then
		echo "initrd /amd-ucode.img" >> /boot/loader/entries/arch.conf
	fi
	if [[ "$cpu" = "intel" ]]
	then
		echo "initrd /intel-ucode.img" >> /boot/loader/entries/arch.conf
	fi
	echo "initrd /initramfs-linux.img" >> /boot/loader/entries/arch.conf
	echo "options root=$root rw" >> /boot/loader/entries/arch.conf

	echo "title Arch Linux (fallback initramfs)" > /boot/loader/entries/arch-fallback.conf
	echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch-fallback.conf
	if [[ "$cpu" = "amd" ]]
	then
		echo "initrd /amd-ucode.img" >> /boot/loader/entries/arch-fallback.conf
	fi
	if [[ "$cpu" = "intel" ]]
	then
		echo "initrd /intel-ucode.img" >> /boot/loader/entries/arch-fallback.conf
	fi
	echo "initrd /initramfs-linux-fallback.img" >> /boot/loader/entries/arch-fallback.conf
	echo "options root=$root rw" >> /boot/loader/entries/arch-fallback.conf

	echo "#timeout 3
	#console-mode keep

	default arch-zen.conf
	timeout 4
	console-mode max
	editor yes" > /boot/loader/loader.conf

	echo "Post Installation"
	echo "Enable Systemd timers/services"
	systemctl enable snapper-boot.timer
	systemctl enable snapper-cleanup.timer
	systemctl enable snapper-timeline.timer
	systemctl enable sddm
	systemctl enable NetworkManager

	echo "Add user $username as sudoer"
	useradd -m $username
	passwd $username
	echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

	echo "Get Post install script"
	cd /home/$username
	curl -O 10.0.1.12:8000/post-arch-install.sh
	chmod +x post-arch-install.sh
}

echo "3.2 Chroot"
export -f archroot # makes the function visible to the arch-chroot
arch-chroot /mnt /bin/bash -c "archroot $root $hostname $cpu $username" || echo "arch-chroot returned: $?"

#umount -R /mnt