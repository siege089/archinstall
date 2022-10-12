#!/bin/bash

echo "starting script" | tee arch-install.log
error_exit()
{
	echo "Error: $1"
	exit 1
}





echo "1.9.1 Example layouts - UEFI with GPT (no swap)"
partitions=($(fdisk -l 2> /dev/null | awk -v var="$disk" '$1 ~ var { print $1 }'))
reverse() {
    # first argument is the array to reverse
    # second is the output array
    declare -n arr="$1" rev="$2"
    for i in "${arr[@]}"
    do
        rev=("$i" "${rev[@]}")
    done
}
reverse partitions partitions_rev
for i in "${partitions_rev[@]}"
do
	echo "Deleting partition $i"
	wipefs -a "$i" >> arch-install.log
	(echo "d"; echo ""; echo "w") | fdisk $disk >> arch-install.log
done
wipefs -a "$disk" >> arch-install.log

echo "Setting up partitions"
(echo "g"; echo "n"; echo ""; echo ""; echo "+512M"; echo "t"; echo "1"; echo "n"; echo ""; echo ""; echo ""; echo "t";  echo "2"; echo "20"; echo "p"; echo "w") | fdisk $disk >> arch-install.log

echo "1.10 Format the partitions"
partitions=($(fdisk -l 2> /dev/null | awk -v var="$disk" '$1 ~ var { print $1 }'))
root=""
boot=""
for i in "${partitions[@]}"
do
	if [[ $i == *1 ]]
	then
		boot="$i"
		mkfs.fat -F 32 $i >> arch-install.log
	fi
	if [[ $i == *2 ]]
	then
		root="$i"
		mkfs.btrfs -f $i >> arch-install.log
	fi
done

echo "1.11 Mount the file systems"
mount $root /mnt
mount --mkdir $boot /mnt/boot


echo "2.1 Select the mirrors"
#echo 'Server = https://archmirror.cjfravel.dev/' > /etc/pacman.d/localcache
echo 'Server = https://archmirror.cjfravel.dev/$repo/os/$arch' > /etc/pacman.d/localcache
reflector -l 200 -n 20 -p https -c "United States" --save /etc/pacman.d/sorted
cat /etc/pacman.d/sorted >> /etc/pacman.d/localcache
cp /etc/pacman.d/localcache /etc/pacman.d/mirrorlist

echo "2.2 Install essential packages"
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
pacstrap -K /mnt base linux linux-headers linux-zen linux-zen-headers linux-firmware nano networkmanager openssh snapper zsh bluez-utils blueman alacritty plasma xorg sudo git base-devel
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

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