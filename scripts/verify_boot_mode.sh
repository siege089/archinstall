error_exit()
{
	echo "Error: $1" | tee -a arch-install.log
	exit 1
}

echo "1.6 Verify the boot mode" | tee -a arch-install.log
ls /sys/firmware/efi/efivaros &> /dev/null || error_exit "Not in UEFI Boot Mode https://wiki.archlinux.org/title/installation_guide#Verify_the_boot_mode"
