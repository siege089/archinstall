username=$1
password=$2

echo "Add user $username as sudoer"
useradd -m -G wheel $username
echo "$username:$password" | chpasswd
echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers