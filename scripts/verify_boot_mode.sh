echo "1.6 Verify the boot mode"
ls /sys/firmware/efi/efivaros &> /dev/null || exit 1
