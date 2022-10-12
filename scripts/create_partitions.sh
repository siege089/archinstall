disk=$1

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