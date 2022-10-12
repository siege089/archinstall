echo "2.1 Select the mirrors"
reflector -l 200 -n 20 -p https -c "United States" --save /etc/pacman.d/mirrorlist
