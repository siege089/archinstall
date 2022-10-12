import os
import re
import subprocess


def get_cpu_type():
    command = "cat /proc/cpuinfo"
    all_info = subprocess.check_output(command, shell=True).decode().strip()
    for line in all_info.split("\n"):
        if "vendor_id" in line:
            return re.sub(".*vendor_id.*:", "", line, 1).strip()


def call_script(script, error_message=None, supress_error=False):
    command = f"bash scripts/{script}"
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        return output.decode().strip()
    except subprocess.CalledProcessError as exc:
        if not supress_error:
            if error_message is not None:
                raise Exception(error_message)
            raise Exception(exc.stdout)


def present_options(options, message):
    user_input = ''

    input_message = f"{message}:\n"
    for index, item in enumerate(options):
        input_message += f'{index + 1}) {item}\n'

    while user_input not in map(str, range(1, len(options) + 1)):
        user_input = input(input_message)

    return int(user_input)-1


def select_disk():
    command = "fdisk -l 2> /dev/null | awk '/^Disk \//{print substr($2,0,length($2)-1)}'"
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        disk_options = output.decode().strip().splitlines()
        return disk_options[present_options(disk_options, "Select a disk")]

    except subprocess.CalledProcessError as exc:
        raise Exception(exc.stdout)


call_script("verify_boot_mode.sh", "Not in UEFI Boot Mode https://wiki.archlinux.org/title/installation_guide#Verify_the_boot_mode")
call_script("connect_to_internet.sh")
call_script("update_system_clock.sh")
disk = select_disk()
hostname = input("Enter a hostname:\n")
cpu_type = get_cpu_type()
intel = False
amd = False
if cpu_type == "AuthenticAMD":
    amd = True
elif cpu_type == "GenuineIntel":
    intel = True

os.system("stty -echo")
root_password = input("Enter password for root:\n")
os.system("stty echo")

username = input("Enter a username:\n")

os.system("stty -echo")
user_password = input(f"Enter password for {username}:\n")
os.system("stty echo")

print("\n")
print("********************")
print(f"Hostname: {hostname}")
print(f"Selected Disk: {disk} !!! DISK WILL BE FORMATTED AND ALL DATA ERASED !!!")
print(f"Username: {username}")
print("********************")
if present_options(["Yes", "No"], "Confirm Installation") != 0:
    raise Exception("Installation Aborted")

call_script("unmount.sh", supress_error=True)
call_script(f"create_partitions.sh {disk}")
boot = call_script(f"get_boot_partition.sh {disk}")
root = call_script(f"get_root_partition.sh {disk}")
print(root)
print(boot)