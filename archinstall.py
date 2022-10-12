import subprocess, re


def get_cpu_type():
    command = "cat /proc/cpuinfo"
    all_info = subprocess.check_output(command, shell=True).decode().strip()
    for line in all_info.split("\n"):
        if "vendor_id" in line:
            return re.sub(".*vendor_id.*:", "", line, 1).strip()


def call_script(script, error_message=None):
    command = f"bash scripts/{script}"
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as exc:
        if error_message is not None:
            raise Exception(error_message)
        raise Exception(exc.stdout)


def select_disk():
    command = "fdisk -l 2> /dev/null | awk '/^Disk \//{print substr($2,0,length($2)-1)}'"
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        disk_options = output.decode().strip().splitlines()
        user_input = ''

        input_message = "Pick an option:\n"
        for index, item in enumerate(disk_options):
            input_message += f'{index + 1}) {item}\n'
        while user_input.lower() not in disk_options:
            user_input = input(input_message)



    except subprocess.CalledProcessError as exc:
        if error_message is not None:
            raise Exception(error_message)
        raise Exception(exc.stdout)


call_script("verify_boot_mode.sh", "Not in UEFI Boot Mode https://wiki.archlinux.org/title/installation_guide#Verify_the_boot_mode")
call_script("connect_to_internet.sh")
call_script("update_system_clock.sh")
select_disk()
print(get_cpu_type())
