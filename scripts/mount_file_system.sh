root=$1
boot=$2

echo "1.11 Mount the file systems"
mount $root /mnt
mount --mkdir $boot /mnt/boot
