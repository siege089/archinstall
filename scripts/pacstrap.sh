packages=$1

echo "2.2 Install essential packages"
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
pacstrap -K /mnt $packages
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
