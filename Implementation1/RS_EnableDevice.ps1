# Copyright © 2008, Microsoft Corporation. All rights reserved.


#RS_EnableDevice.ps1
PARAM($DeviceName, $DeviceID, $ErrorCode)

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.Resolution_EnableDevice

$IsEnabled = EnableDevice $DeviceID $True $True

$TargetObject = Get-WmiObject -Class "Win32_PNPEntity" | Where-Object -FilterScript {$_.PNPDeviceID -eq $DeviceID}

if(($IsEnabled -eq $False) -or (($TargetObject -ne $Null) -and ($TargetObject.ConfigManagerErrorCode -eq $ErrorCode)))
{
    EnableDevice $DeviceID $True $False
}
