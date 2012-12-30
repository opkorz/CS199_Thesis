# Copyright © 2008, Microsoft Corporation. All rights reserved.


#TS_HardwareDevice
PARAM($DeviceID)

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

. .\DB_DeviceErrorLibrary.ps1

$RootCauseAdded = $false
Write-DiagProgress -activity $localizationString.Troubleshoot_HardwareDevices

$ProblemDevice = Get-WmiObject -Class Win32_PnPEntity | Where-Object -FilterScript {$_.DeviceID -eq $DeviceID}

if(($ProblemDevice -ne $Null) -and ($ProblemDevice.ConfigManagerErrorCode -ne $Null))
{
    [string]$DeviceName = $ProblemDevice.Name
    [string]$ErrorCode = $ProblemDevice.ConfigManagerErrorCode

    if ([String]::IsNullOrEmpty($DeviceName))
    {
        $DeviceName = $localizationString.UnknownDevice
    }

    if($HashDeviceErrors.Contains($ErrorCode) -eq $True)
    {
        Update-DiagRootCause -id RC_NotWorkingProperly -iid $DeviceID -Detected $true -p @{'DeviceName'= $DeviceName; 'DeviceID'= $DeviceID; 'ErrorCode'= $ErrorCode}
        $ProblemDevice | Select-Object -Property @{Name=$localizationString.DeviceName; Expression={$_.Name}}, @{Name=$localizationString.PnPDeviceID; Expression={$_.PNPDeviceID}}, @{Name=$localizationString.ConfigManagerErrorCode; Expression={$_.ConfigManagerErrorCode}} | ConvertTo-XML | Update-DiagReport -ID DeviceNotWorkingProperly -Name $localizationString.Report_Name_ProblemDevice -Verbosity Informational -rid RC_NotWorkingProperly -riid $DeviceID
        $RootCauseAdded = $True
    }
}
return $RootCauseAdded
