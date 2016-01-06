# NanoVHD
Scripts to build and test a virtual machine image using the Nano Server installation option of Windows Server 2016

This repo contains 3 simple scripts.
  *  *NanoBuild.ps1* - Automates creation of a VHD for Nano Server from the Windows Server 2016 Technical Preview 4 Evaluation media
  *  *NanoBuild.Tests.ps1* - Pester script to verify the newly built image meets basic expectations (improvements welcome)
  *  *NanoVMConfig.ps1* - PowerShell Desired State Configuration script to configure a Windows 10 machine to create and boot a new VM in Hyper-V (edit name of NIC and location of VHD)