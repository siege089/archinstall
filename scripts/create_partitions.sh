disk=$1

echo "1.9.1 Example layouts - UEFI with GPT (no swap)"
echo "Erase disk"
sgdisk -Z $disk

echo "Setting up partitions"
(echo "g"; echo "n"; echo ""; echo ""; echo "+512M"; echo "t"; echo "1"; echo "n"; echo ""; echo ""; echo ""; echo "t";  echo "2"; echo "20"; echo "p"; echo "w") | fdisk $disk >> arch-install.log

echo "1.10 Format the partitions"
partitions=($(fdisk -l 2> /dev/null | awk -v var="$disk" '$1 ~ var { print $1 }'))
for i in "${partitions[@]}"
do
	if [[ $i == *1 ]]
	then
		mkfs.fat -F 32 $i >> arch-install.log
	fi
	if [[ $i == *2 ]]
	then
		mkfs.btrfs -f $i >> arch-install.log
	fi
done