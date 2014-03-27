import psutil
import servicemanager
import subprocess
import sys
import win32service
import win32serviceutil

def kill_proc_tree(pid, including_parent=True):
    parent = psutil.Process(pid)
    for child in parent.get_children(recursive=True):
        servicemanager.LogInfoMsg("OpenStack Ceilometer Agent Compute: Stopping (Killing child: %s)" % child)
        child.kill()
    if including_parent:
        servicemanager.LogInfoMsg("OpenStack Ceilometer Agent Compute: Stopping (Killing parent: %s)" % parent)
        parent.kill()

class CeilometerAgentComputeService(win32serviceutil.ServiceFramework):
    _svc_name_ = "ceilometer-agent-compute"
    _svc_display_name_ = "ceilometer-agent-compute"
    _svc_description_ = "OpenStack Ceilometer Agent Compute service for Hyper-V"

    def __init__(self,args):
        win32serviceutil.ServiceFramework.__init__(self,args)
        self.p = None

    def SvcDoRun(self):
        servicemanager.LogInfoMsg('OpenStack Ceilometer Agent Compute: Starting (C:\\Python27\\Scripts\\ceilometer-agent-compute.exe %s)' % sys.argv[1])
        self.p = subprocess.Popen(["C:\\Python27\\Scripts\\ceilometer-agent-compute.exe", sys.argv[1]])
        self.p.wait()
        servicemanager.LogInfoMsg("OpenStack Ceilometer Agent Compute: Stopped")

    def SvcStop(self):
        servicemanager.LogInfoMsg("OpenStack Ceilometer Agent Compute: Recieved stop signal")
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        kill_proc_tree(self.p.pid)

if __name__ == '__main__':
    win32serviceutil.HandleCommandLine(CeilometerAgentComputeService)

