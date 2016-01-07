#Requires -Version 5
#Requires -RunAsAdministrator
#Requires -Modules xHyper-V,xDismFeature,xPSDesiredStateconfiguration
#
# Nano Server installation option of Windows Server Technical Preview 4 for Developers 
# Host Configuration Test Script v0.1
#
# To install the required DSC modules from the PowerShell Gallery
#     Install-Module xHyper-V,xDismFeature,xPSDesiredStateconfiguration -Force
# 
# This script applies a PowerShell DSC configuration to the local host to download the
# Nano evaluation VHD and configure a VM to run it for testing.
#
# Considerations:
#  -  Adding Hyper-V to your workstation might require a reboot.
#  -  The script will configure a new virtual switch and VM.  The names are configured as
#     static variables below.  Be sure to avoid conflicts with existing configurations.
#
#

# Static
$VMName = 'Nano1'
$SwitchName = 'PrivateSwitch'
$VMPath = "c:\VM\$VMhName"
$WorkingDir = 'c:\dsc\NanoVM\'

# The Terms and Conditions for the evaluation VHD must be accepted before download.
$choiceList = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]
$choiceList.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList "&No"))
$choiceList.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList "&Yes"))
$eulaText = @"
Before installing and using the Nano Server install option of Windows Server Technical Preview 4 for Developers VHD you must: 
    1.	Review the license terms by navigating to this link: http://aka.ms/nanoeval
    2.	Print and retain a copy of the license terms for your records.
By downloading and using the Nano Server install option of Windows Server Technical Preview 4 for Developers VHD you agree to such license terms. Please confirm you have accepted and agree to the license terms.
"@
$EULA = [boolean]$Host.ui.PromptForChoice($null, $eulaText, $choiceList, 0)

# If T&C are accepted, configure localhost with Nano VM based on Static values
If ($EULA -eq $true) {

    Configuration NanoVM
    {
        Import-DscResource -module xHyper-V, xDismFeature, xPSDesiredStateconfiguration, PSDesiredStateconfiguration
        Node localhost
        {
            # xDismFeature is used with the assumption this is tested on a Win10 machine as opposed to a server where the WindowsFeature resource could be used
            xDismFeature HyperV
            {
                Ensure               = 'Present'
                Name                 = 'Microsoft-Hyper-V-All'
            }
        
            # The Hyper-V PowerShell module is added for local administration (get-vm, start-vm, stop-vm)
            xDismFeature HyperVPSModule
            {
                Ensure               = 'Present'
                Name                 = 'Microsoft-Hyper-V-Management-PowerShell'
                DependsOn            = '[xDismFeature]HyperV'
            }

            # The management client is required if you need to connect to the console, for example to set the password, use "vmconnect localhost vmname"
            xDismFeature VMConnect
            {
                Ensure               = 'Present'
                Name                 = 'Microsoft-Hyper-V-Management-Clients'
                DependsOn            = '[xDismFeature]HyperV'
            }

            # This section can be modified to use an external/internal switch which would be desireable in most cases but you need to decide if you are sharing the adapter with the management OS
            xVMSwitch $SwitchName
            {
                Ensure               = 'Present'
                Name                 = $SwitchName
                Type                 = 'Private'
                #Type                = 'External'
                #NetAdapterName      = 'Wifi'
                #AllowManagementOS   = $true
                DependsOn            = '[xDismFeature]HyperV'
            }

            # VHD should be present, if not, download it
            xRemoteFile CopyVHD
            {
                Uri                  = 'http://aka.ms/nanoevalvhd'
                DestinationPath      = "$VMPath\$VMName\$VMName.vhd"
                MatchSource          = $false
            }

            # Virtual machine should be configured in Hyper-V
            xVMHyperV Nano
            {
                Ensure               = 'Present'
                Name                 = $VMName
                VhdPath              = "$VMPath\$VMName\$VMName.vhd"
                SwitchName           = $SwitchName
                Path                 = $VMPath
                Generation           = 1
                StartupMemory        = 512MB
                ProcessorCount       = 1
                State                = 'Running'
                DependsOn            = '[xDismFeature]HyperV',"[xVMSwitch]$SwitchName"
            }
        }
    }

    NanoVM -out $WorkingDir
    Start-DscConfiguration -wait -verbose -path $WorkingDir -force
}