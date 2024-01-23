# vmware-powercli

# Shutdown vm

- add vm names in vm.txt

- edit the variables of $vcenter_ip, $vcenter_admin and $vcenter_pass

- run .\vmware-powercli.ps1 shutdownvm "Datacenter brian"

# Unregister vm

- run .\vmware-powercli.ps1 unregistervm "Datacenter brian"

# Register vm

- run .\vmware-powercli.ps1 registervm "Datacenter brian"

# Startup vm

- run .\vmware-powercli.ps1 startupvm "Datacenter brian"
