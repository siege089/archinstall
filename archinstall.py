import os
import re
import subprocess


def get_cpu_type():
    command = "cat /proc/cpuinfo"
    all_info = subprocess.check_output(command, shell=True).decode().strip()
    for line in all_info.split("\n"):
        if "vendor_id" in line:
            return re.sub(".*vendor_id.*:", "", line, 1).strip()


def call_command(command, error_message=None, supress_error=False):
    command = f"bash {command}"
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        return output.decode().strip()
    except subprocess.CalledProcessError as exc:
        if not supress_error:
            if error_message is not None:
                raise Exception(error_message)
            raise Exception(exc.stdout)


def call_script(script, error_message=None, supress_error=False):
    return call_command(f"scripts/{script}", error_message, supress_error)


def chroot_script(script, error_message=None, supress_error=False):
    return call_command(f"arch-chroot /mnt bash /usr/local/share/archinstall/scripts/{script}", error_message, supress_error)


def present_options(options, message, descriptions=None):
    user_input = ''

    input_message = f"{message}:\n"
    for index, item in enumerate(options):
        input_message += f'{index + 1}) {item}\n'
        if descriptions is not None:
            input_message += f"\t{descriptions[index]}\n"

    while user_input not in map(str, range(1, len(options) + 1)):
        user_input = input(input_message)

    return int(user_input) - 1


def select_disk():
    command = "fdisk -l 2> /dev/null | awk '/^Disk \//{print substr($2,0,length($2)-1)}'"
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        disk_options = output.decode().strip().splitlines()
        return disk_options[present_options(disk_options, "Select a disk")]

    except subprocess.CalledProcessError as exc:
        raise Exception(exc.stdout)


YES_NO = ["Yes", "No"]
INSTALL_TYPES = ["Server", "Desktop"]
INSTALL_TYPES_DESC = ["Subtypes Presented Later",
                      "Alacritty terminal, KDE desktop with login, bluetooth support, Pipewire audio"]
SERVER_TYPES = ["Hadoop"]

call_script("verify_boot_mode.sh",
            "Not in UEFI Boot Mode https://wiki.archlinux.org/title/installation_guide#Verify_the_boot_mode")
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
#
# username = input("Enter a username:\n")
#
# os.system("stty -echo")
# user_password = input(f"Enter password for {username}:\n")
# os.system("stty echo")

print("\n")
print("********************")
# print(f"Hostname: {hostname}")
# print(f"Selected Disk: {disk} !!! DISK WILL BE FORMATTED AND ALL DATA ERASED !!!")
# print(f"Username: {username}")
print("********************")
if YES_NO[present_options(YES_NO, "Confirm Installation")] == "No":
    raise Exception("Installation Aborted")

call_script("unmount.sh", supress_error=True)
# call_script(f"create_partitions.sh {disk}")
boot = call_script(f"get_boot_partition.sh {disk}")
root = call_script(f"get_root_partition.sh {disk}")
call_script(f"mount_file_system.sh {root} {boot}")

# if YES_NO[present_options(YES_NO, "Provide specific mirror?")] == "Yes":
#     mirror = input("Enter mirror root:\n")
#     call_script(f"select_custom_mirror.sh '{mirror}'")
# else:
#     call_script("select_mirror.sh")

install_type = INSTALL_TYPES[present_options(INSTALL_TYPES, "Select Install type", INSTALL_TYPES_DESC)]
packages = "base linux linux-headers linux-zen linux-zen-headers linux-firmware nano networkmanager openssh snapper zsh sudo git base-devel"
cpu = ""
if amd:
    packages += " amd-ucode"
    cpu = "amd"
if intel:
    packages += " intel-ucode"
    cpu = "intel"
if install_type == "Desktop":
    packages += " bluez-utils blueman alacritty plasma xorg pipewire"

# call_script(f"pacstrap.sh {packages}")
# call_script("fstab.sh")

call_script("copy_install_scripts.sh")
chroot_script("set_timezone.sh")
chroot_script("set_localization.sh")
chroot_script(f"set_network_configuration.sh {hostname}")
chroot_script(f"set_root_password.sh {root_password}")
chroot_script(f"set_boot_loader.sh {cpu} {root}")
