#Requires -Modules Pester
<#
.SYNOPSIS
    Tests a Nano image in a local Hyper-V VM
.EXAMPLE
    Invoke-Pester 
.NOTES
    This file has been created as an example of using Pester to evaluate ARM templates
#>

$VM = 'TP4_Nano'
$HyperVVMLocations = 'C:\VM\'
$IP = get-vm $VM | % networkadapters | % ipaddresses | ? {$_ -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"}
$VHD = Join-Path (Join-Path $HyperVVMLocations $VM) Nano.vhd
$State = Get-VM $VM | % State

Describe "VM: $VM" -Tags Unit {
    
    Context "VHD check" {
        
        if ((Get-VM $VM | % State) -eq 'Running') {
            Stop-VM $VM
            Write-Verbose 'Sleeping 5 seconds while VM stops'
            Start-Sleep 5
            }
                
        if ((Get-VHD $VHD).Attached -eq $false) {
            $MountVHD = Mount-VHD $VHD -Passthru | Get-Disk | Get-Partition | Get-Volume
            }

        It "mounts as a drive" {        
            Test-Path ($MountVHD.driveletter + ':') | Should Be True
        }

        $UnattendXMLFile = Join-Path ($MountVHD.driveletter + ':') 'Windows\Panther\Unattend.XML'
                
        It "does not contain an answer file" {        
            Test-Path $UnattendXMLFile | Should Be False And Not Null
        }
        
        if ((Get-VHD $VHD).Attached -eq $true) {
            Dismount-VHD $VHD
            }
        
        
    }

    Context "VM health" {

        if ((Get-VM $VM | % State) -eq 'Off') {
            Start-VM $VM
            Write-Verbose 'Sleeping for 15 seconds while VM starts and connects to network'
            Start-Sleep 15
            }
          
        It "is running" {        
            Get-VM $VM | % State | Should Be 'Running'
        }
        
        It "has no errors" {        
            Get-VM $VM | % Status | Should Be 'Operating Normally'
        }
        
    }

    Context "Running VM responds over network" {
        
        $Content = invoke-webrequest -Uri $ip | % RawContent

        It "is accessible via WinRM" {
            Write-Verbose 'Ignore the warning for the Ping timeout, we are not allowing ICMP traffic by default in the image.'      
            Test-NetConnection -ComputerName $IP -CommonTCPPort WINRM -InformationLevel Quiet | Should Be True
        }
        
        It "is hosting the default IIS website" {        
            $Content.Substring(472,18) | Should Be 'IIS Windows Server'
        }
        
    }
}

If ((Get-VM $VM | % State) -ne $State) {
    if ($State -eq 'Running') {Start-VM $VM}
    if ($State -eq 'Off') {Stop-VM $VM}
    }