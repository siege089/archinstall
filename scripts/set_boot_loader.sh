	cpu=$1

	echo "3.8 Boot loader"
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
