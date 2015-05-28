# execute in python to allow try/catch of seg faults

import subprocess
import threading
import os
import sys

class Task:
    def __init__(self, timeout=None):
        self.timeout = timeout
        self.process = None

    def check_call(self, *args, **kwargs):
        "Essentially subprocess.check_call with kill switch for compatibility."

        def target():
            self.process = subprocess.Popen(*args, **kwargs)
            self.process.communicate()

        thread = threading.Thread(target=target)
        thread.start()

        thread.join(self.timeout)
        if thread.is_alive():
            self.process.terminate()
            thread.join()

        if self.process.returncode != 0:
            raise SystemError((self.process.returncode, str(args[0])))
        else:
            return 0


##
# @brief Non-threaded version of check_call.
#
#        This allows items to be easily executed by the harness so that a 
#        task does not always have to be created first. The threaded version
#        should be used in almost all cases when executing non-system programs
#
def check_call(*args, **kwargs):
    "Essentially subprocess.check_call for compatibility reasons."

    import subprocess
    returnValue = subprocess.call(*args, **kwargs)
    if returnValue != 0:
        raise SystemError((returnValue, str(args[0])))
    else:
        return 0




t = Task(10)
passed_exe = sys.argv[1]
outf = sys.argv[2]

try:
    with open(outf, 'a+') as out_file:
        t.check_call([passed_exe], stdout=out_file, stderr=out_file)
except SystemError as e:
    if e[0][0] == -11:
        print "Execution terminated due to a segmentation fault"
    elif e[0][0] == -15:
        print "Execution terminated due to program taking too long"

