import subprocess, re


def get_cpu_type():
    command = "cat /proc/cpuinfo"
    all_info = subprocess.check_output(command, shell=True).decode().strip()
    for line in all_info.split("\n"):
        if "vendor_id" in line:
            return re.sub(".*vendor_id.*:", "", line, 1).strip()


def verify_boot_mode():
    command = "bash scripts/verify_boot_mode.sh"
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as exc:
        raise Exception(
            "Not in UEFI Boot Mode https://wiki.archlinux.org/title/installation_guide#Verify_the_boot_mode")


def connect_to_internet():
    command = "bash scripts/connect_to_internet.sh"
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as exc:
        raise Exception(exc.stdout)


verify_boot_mode()
connect_to_internet()
print(get_cpu_type())
