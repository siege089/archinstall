mirror=$1

echo "2.1 Select the mirrors"
echo "Server = $mirror/\$repo/os/\$arch" > /etc/pacman.d/localcache
reflector -l 200 -n 20 -p https -c "United States" --save /etc/pacman.d/sorted
cat /etc/pacman.d/sorted >> /etc/pacman.d/localcache
cp /etc/pacman.d/localcache /etc/pacman.d/mirrorlist
