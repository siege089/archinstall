import subprocess, re

def get_cpu_type():
    command = "cat /proc/cpuinfo"
    all_info = subprocess.check_output(command, shell=True).decode().strip()
    for line in all_info.split("\n"):
        if "vendor_id" in line:
            return re.sub( ".*vendor_id.*:", "", line,1).strip()

def verify_boot_mode():
    command = "bash scripts/verify_boot_mode.sh"
    try:
        output = subprocess.check_output(command, shell=True, stderr=STDOUT)
    except ChildProcessError as exc:
        print(exc.output)
    else:
        assert 0

verify_boot_mode()
print(get_cpu_type())
