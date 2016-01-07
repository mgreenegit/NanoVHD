Install-Module xHyper-V,xDismFeature -Force

Configuration testbox
{
    Import-DscResource -module xHyper-V, xDismFeature
    Node localhost
    {
        xDismFeature HyperV
        {
            Ensure = 'Present'
            Name   = 'Microsoft-Hyper-V-All'
        }
        
        xDismFeature HyperVPSModule
        {
            Ensure = 'Present'
            Name   = 'Microsoft-Hyper-V-Management-PowerShell'
            DependsOn =  '[xDismFeature]HyperV'
        }

        xDismFeature VMConnect
        {
            Ensure = 'Present'
            Name   = 'Microsoft-Hyper-V-Management-Clients'
            DependsOn =  '[xDismFeature]HyperV'
        }

        xVMSwitch ExternalSwitch
        {
            Ensure         = 'Present'
            Name           = 'Ext'
            Type           = 'External'
            NetAdapterName = 'Wi-Fi'
            AllowManagementOS = $True
            DependsOn =  '[xDismFeature]HyperV'
        }

        File VMFolder
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'C:\VM\tp4_Nano\'
        }

        File CopyVHD
        {
            Ensure = 'Present'
            SourcePath = 'C:\VM\Nano.vhd'
            DestinationPath = 'C:\VM\tp4_Nano\Nano.vhd'
        }
        
        xVMHyperV Nano
        {
            Ensure          = 'Present'
            Name            = 'TP4_Nano'
            VhdPath         = 'C:\VM\nano.vhd'
            SwitchName      = 'Ext'
            Path            = 'C:\VM\tp4_nano\'
            Generation      = 1
            StartupMemory   = 1GB
            ProcessorCount  = 1
            State = 'Off'
            DependsOn       = '[xDismFeature]HyperV','[xVMSwitch]ExternalSwitch'
        }
    }
}
testbox -out c:\dsc\testbox\
Start-DscConfiguration -wait -verbose -path c:\dsc\testbox\ -force
