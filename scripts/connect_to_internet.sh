echo "1.7 Connect to the internet"
linkup=`ip link | awk '/state UP/'`
if [[ $linkup == "" ]]
then
	error_exit "Connect to internet first"
fi