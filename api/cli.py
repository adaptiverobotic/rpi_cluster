import subprocess
from shelljob import proc

cli = "../cli/cli.sh"

# -------------------------------------------------------------------------------

def execute(command):
    return 1

# -------------------------------------------------------------------------------

# Install firewall on sysadmin server
def command(method, arg):
    line=""
    cmd=[cli, method, arg]

    # Execute the command
    popen = subprocess.Popen(cmd, stdout=subprocess.PIPE, universal_newlines=False)

    # Print to console as they show up
    for stdout_line in iter(popen.stdout.readline, ""):
        line = str(stdout_line)

        # Empty byte stream
        if line != "b''":
            yield line + "<br>"

    # Close the input stream
    popen.stdout.close()

    # Get the exit code
    return_code = popen.wait()

    # If an error occured
    if return_code:
        raise subprocess.CalledProcessError(return_code, cmd)
