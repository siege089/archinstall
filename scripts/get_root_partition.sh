disk=$1

partitions=($(fdisk -l 2> /dev/null | awk -v var="$disk" '$1 ~ var { print $1 }'))
for i in "${partitions[@]}"
do
	if [[ $i == *2 ]]
	then
	  echo $i
	fi
done