$vcenter_ip = "10.1.5.44"
$vcenter_admin = 'administrator@vsphere.local'
$vcenter_pass = 'P@ssw0rd'



$config_filename = "vm-config.csv"

function RemoveOldConfig {

    if (Test-Path $config_filename) {
        Remove-Item $config_filename
    }
}

function checkDC($dc_name) {
    $dc = Get-Datacenter -Name $dc_name
    if (!$dc) {
        write-host "Datacenter $dc_name not found."
        exit
    }
    return $dc
}


function startVMs($vm_list, $dc_name) {

    $dc = checkDC($dc_name)
    foreach ($vm in $vm_list)
    {
        # $v = Get-VM -Name $vm -Location $dc
        # if (!$v) {
        #     Write-Host "Error: $vm does not exist."
        #     continue
        # }
        try {
            $v = Get-VM -Name $vm -Location $dc -ErrorAction 'Stop'
        } catch [Exception]{
            Write-Host "Error: cannot find vm $vm."
            continue
        }
        if ($v.PowerState -ne "PoweredOn") {
            Start-VM -VM $v
        } else {
            Write-Host "Warning: $vm is already powered on."
        }
    }
}

function shutDownVms($vm_list, $dc_name) {
    $dc = checkDC($dc_name)
    foreach ($vm in $vm_list)
    {
        try {
            $v = Get-VM -Name $vm -Location $dc -ErrorAction 'Stop'
        } catch [Exception]{
            Write-Host "Error: cannot find vm $vm."
            continue
        }
        # $v = Get-VM -Name $vm -Location $dc
        # if (!$v) {
        #     Write-Host "Error: $vm does not exist."
        #     continue
        # }
        $vm_tools = Get-VMGuest -VM $v
        if ($vm_tools.ToolsVersion)
        {
            if ($v.PowerState -eq "PoweredOn") {
                write-host "Shutting down $vm ..."
                Shutdown-VMGuest -VM $v -confirm:$false
            }
        } else {
            if ($v.PowerState -eq "PoweredOn") {
                write-host "Powering off $vm ..."
                Stop-VM -VM $v -confirm:$false
            }
        }
    
    }
}


function unRegisterVMs($vm_list, $dc_name) {
    $dc = checkDC($dc_name)
    RemoveOldConfig
    foreach ($vm in $vm_list)
    {
        # $v = Get-VM -Name $vm -Location $dc
        # if (!$v) {
        #     Write-Host "Error: $vm does not exist."
        #     continue
        # }
        try {
            $v = Get-VM -Name $vm -Location $dc -ErrorAction 'Stop'
        } catch [Exception]{
            Write-Host "Error: cannot find vm $vm."
            continue
        }
        # $v
        # $v.ExtensionData.Config.Files.VmPathName
        $o = New-Object -TypeName PSObject -Property @{
            Name = $v.Name
            Vmx = $v.ExtensionData.Config.Files.VmPathName
            ResourcePoolId = $v.ResourcePoolId
            HostId= $v.VMHostId
            FolderId = $v.FolderId
        }
        $o | Export-Csv -Path $config_filename -NoTypeInformation -Append
        try {
            Remove-VM -VM $v -Confirm:$false -ErrorAction 'Stop'
            Write-Host "Info: $vm is unregistered successfully."
        } catch [Exception] {
            Write-Host "Error: failed to unregister $vm."
            continue
        }
    }
}


function registerVMs {
    # $dc = Get-Datacenter -Name "Datacenter brian"
    $IM = Import-Csv -Path $config_filename
    foreach ($i in $IM) {
        $rp = Get-ResourcePool -Id $i.ResourcePoolId
        $h = Get-VMHost -Id $i.HostId
        $fd = Get-Folder -Id $i.FolderId
        New-VM -VMFilePath $i.Vmx -ResourcePool $rp -VMHost $h -Location $fd
    }
}


function main($arguments) {
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore
    try {
        Connect-VIServer -Server $vcenter_ip -Protocol https -User $vcenter_admin -Password $vcenter_pass -ErrorAction 'Stop'
    } catch [Exception] {
        Write-Host "Error: failed to connect to VCenter."
        exit
    }

    # Read VM list
    $vm_list = Get-Content vm.txt
        

    $action = $arguments[0].ToLower()
    $dc_name = $arguments[1]

    switch ($action) {
        "shutdownvm" {
            shutDownVMs $vm_list $dc_name
        }
        "unregistervm" {
            unregisterVMs $vm_list $dc_name
        }
        "registervm" {
            registerVMs
        }
        "startvm" {
            startVMs $vm_list $dc_name
        }
        default {
            Write-Host "Error: argument action is not valid"
            Write-Host "Usage: .\vmware-powercli shutdownvm datacenter"
            Write-Host "Usage: .\vmware-powercli unregistervm datacenter"
            Write-Host "Usage: .\vmware-powercli registervm datacenter"
            Write-Host "Usage: .\vmware-powercli startvm datacenter"
        }
    }
}


if ($args.length -lt 2) {
    Write-Host "Error: no action is added."
    Write-Host "Usage: .\vmware-powercli shutdownvm datacenter"
    Write-Host "Usage: .\vmware-powercli unregistervm datacenter"
    Write-Host "Usage: .\vmware-powercli registervm datacenter"
    Write-Host "Usage: .\vmware-powercli startvm datacenter"
    exit
}

main($args)






