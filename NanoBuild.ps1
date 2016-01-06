# Static Path Variables
$WorkingPath = 'C:\NanoBuild'
$ISOPath = 'C:\VM\10586.0.151029-1700.TH2_RELEASE_SERVER_OEMRET_X64FRE_EN-US.ISO'

# Mount ISO if not already present and get drive letter
if ((Get-DiskImage $ISOPath).Attached -ne $true) {
    $MediaDriveLetter = Mount-DiskImage $ISOPath -PassThru | Get-Volume | % DriveLetter
    $MediaPath = $MediaDriveLetter + ':'
    }
else {
    $MediaDriveLetter = Get-DiskImage $ISOPath | Get-Volume
    $MediaPath = $MediaDriveLetter + ':'
    }

# Verify paths
if (!(Test-Path $MediaPath)) {
    Write-Warning 'The Media Path is not available.'
    Exit
}
    
# Ensure Working Directory includes Nano scripts
if (!(Test-Path $WorkingPath)) {
    $NewWorkingPath =New-Item $WorkingPath -ItemType Directory
    $ScriptModuleFiles = Get-ChildItem (Join-Path $MediaPath 'NanoServer') *.ps* | % FullName
    $ScriptModule = Copy-Item $ScriptModuleFiles $WorkingPath -Force
    }

# Create Path Variables
$BasePath = Join-Path $WorkingPath 'Base'
$TargetPathFolder = Join-Path $WorkingPath (New-Guid)
$TargetPath = Join-Path $TargetPathFolder 'Nano.vhd'
$DISMLog = Join-Path $env:Temp 'NanoServerImageGenerator (DISM).log'
$ScriptLog = Join-Path $env:Temp 'NanoServerImageGenerator.log'

# Parameters
$Params = @{
    MediaPath = $MediaPath
    BasePath = $BasePath
    TargetPath = $TargetPath
    MaxSize = 100GB
    GuestDrivers = $true
    ReverseForwarders = $true
    Containers = $true
    #Defender = $true
    Packages = 'Microsoft-NanoServer-DSC-Package','Microsoft-NanoServer-IIS-Package'
    EnableRemoteManagementPort = $true
    AdministratorPassword = 'Pass@word1' | ConvertTo-SecureString -AsPlainText -Force # Note that when the unattend file is removed from the image, this does not take effect
    Verbose = $true
    }

Import-Module (Join-Path $WorkingPath 'NanoServerImageGenerator.psm1') -Force -ErrorAction SilentlyContinue
$RequiredModules = $RequiredModules + 'NanoServerImageGenerator'

Write-Host `n
Write-Host "The parameters are: `n"
Write-Host ($Params | Out-String)

# Create Image
New-NanoServerImage @Params

# Preserve Script Log Files
If (Test-Path $DISMLog) {$DISMLogMove = Move-Item $DISMLog $TargetPathFolder}
If (Test-Path $ScriptLog) {$ScriptLogMove = Move-Item $ScriptLog $TargetPathFolder}

# Remove Unattend file (force admin to set password at first logon)
$MountVHD = Mount-VHD $TargetPath -Passthru | Get-Disk | Get-Partition | Get-Volume
$UnattendXMLFile = Join-Path ($MountVHD.driveletter + ':') 'Windows\Panther\Unattend.XML'
if (Test-Path $UnattendXMLFile) {Remove-Item $UnattendXMLFile}
Dismount-VHD $TargetPath

# Dismount ISO
Dismount-DiskImage $ISOPath