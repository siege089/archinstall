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