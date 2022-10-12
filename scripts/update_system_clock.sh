echo "1.8 Update the system clock"
time_synced=`timedatectl status 2> /dev/null | awk '/^System clock synchronized:/{print $4}'`
if [[ $time_synced == "no" ]]
then
	error_exit "test"
fi