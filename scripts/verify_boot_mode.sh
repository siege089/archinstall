echo "1.6 Verify the boot mode"
ls /sys/firmware/efi/efivars &> /dev/null || exit 1
