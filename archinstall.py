import getopt
import os
import re
import subprocess
import sys


def prRed(skk): print("\033[91m {}\033[00m".format(skk))


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


def call_script(script, parameters="", error_message=None, supress_error=False):
    print(script)
    return call_command(f"scripts/{script} {parameters}", error_message, supress_error)


def chroot_script(script, parameters="", error_message=None, supress_error=False, hide_parameters=False):
    if hide_parameters:
        print(script)
    else:
        print(f"{script} {parameters}")
    return call_command(f"arch-chroot /mnt bash /usr/local/share/archinstall/scripts/{script} {parameters}",
                        error_message,
                        supress_error)


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


def get_install_type_str(install_type, server_install_type, desktop_install_type):
    if install_type == "Desktop":
        return f"{install_type} - {desktop_install_type}"
    return f"{install_type} - {server_install_type}"


YES_NO = ["Yes", "No"]
INSTALL_TYPES = ["Server", "Desktop"]
SERVER_TYPES = ["Hadoop"]
DESKTOP_TYPES = ["Plasma", "Budgie"]
DESKTOP_TYPES_DESC = ["https://kde.org/plasma-desktop/", "https://blog.buddiesofbudgie.org"]

full_cmd_arguments = sys.argv
argument_list = full_cmd_arguments[1:]
short_options = "m:n:d:u:"
long_options = ["mirror=", "hostname=", "disk=", "user="]
try:
    arguments, values = getopt.getopt(argument_list, short_options, long_options)
except getopt.error as err:
    # Output error, and return with an error code
    print(str(err))
    sys.exit(2)

mirror = None
hostname = None
disk = None
username = None
for current_argument, current_value in arguments:
    if current_argument in ("-m", "--mirror"):
        mirror = current_value
    if current_argument in ("-n", "--hostname"):
        hostname = current_value
    if current_argument in ("-d", "--disk"):
        disk = current_value
    if current_argument in ("-u", "--user"):
        username = current_value

call_script("verify_boot_mode.sh",
            error_message="Not in UEFI Boot Mode https://wiki.archlinux.org/title/installation_guide#Verify_the_boot_mode")
call_script("connect_to_internet.sh")
call_script("update_system_clock.sh")
if disk is None:
    disk = select_disk()
if hostname is None:
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

if username is None:
    username = input("Enter a username:\n")

os.system("stty -echo")
user_password = input(f"Enter password for {username}:\n")
os.system("stty echo")

server_install_type = None
desktop_install_type = None
install_type = INSTALL_TYPES[present_options(INSTALL_TYPES, "Select Install type")]
packages = "base linux linux-headers linux-zen linux-zen-headers linux-firmware nano networkmanager openssh snapper zsh sudo git base-devel"
cpu = ""
if amd:
    packages += " amd-ucode"
    cpu = "amd"
if intel:
    packages += " intel-ucode"
    cpu = "intel"
if install_type == "Desktop":
    packages += " bluez-utils blueman alacritty xorg pipewire"
    desktop_install_type = DESKTOP_TYPES[present_options(DESKTOP_TYPES, "Select Desktop Type", DESKTOP_TYPES_DESC)]
    if desktop_install_type == "Plasma":
        packages += " plasma"
    if desktop_install_type == "Budgie":
        packages += " sddm budgie-desktop"

print("\n")
print("********************")
print(f"Hostname: {hostname}")
print(f"Selected Disk: {disk}")
print(f"Username: {username}")
print(f"Install Type: {get_install_type_str(install_type, server_install_type, desktop_install_type)}")
print("********************")
prRed("!!! DISK WILL BE FORMATTED AND ALL DATA ERASED !!!")

if YES_NO[present_options(YES_NO, "Confirm Installation")] == "No":
    raise Exception("Installation Aborted")

call_script("unmount.sh", supress_error=True)
call_script("create_partitions.sh", disk)
boot = call_script("get_boot_partition.sh", disk)
root = call_script("get_root_partition.sh", disk)
call_script("mount_file_system.sh", f"{root} {boot}")

if mirror is not None:
    call_script(f"select_custom_mirror.sh '{mirror}'")
else:
    call_script("select_mirror.sh")

prRed("pacstrap will take a while!")
call_script(f"pacstrap.sh '{packages}'")
call_script("fstab.sh")

call_script("copy_install_scripts.sh")
chroot_script("set_timezone.sh")
chroot_script("set_localization.sh")
chroot_script("set_network_configuration.sh", hostname)
chroot_script("set_root_password.sh", parameters=root_password, hide_parameters=True)
chroot_script("set_boot_loader.sh", f"{cpu} {root}")

systemctl_enables = ["snapper-boot.timer", "snapper-cleanup.timer", "snapper-timeline.timer", "NetworkManager"]
if install_type == "Desktop":
    systemctl_enables.append("sddm")
for systemctl_enable in systemctl_enables:
    chroot_script(f"enable_systemctl_item.sh {systemctl_enable}")

chroot_script("add_user.sh", parameters=f"{username} {user_password}", hide_parameters=True)
chroot_script("set_zsh_default_shell.sh root")
chroot_script("set_zsh_default_shell.sh", username)
call_script("copy_postinstall.sh", username)
if mirror is not None:
    chroot_script(f"select_custom_mirror.sh '{mirror}'")
