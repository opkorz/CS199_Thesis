# Copyright © 2008, Microsoft Corporation. All rights reserved.


#TS_HardwareDevice
PARAM($DeviceID, $Action)

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

. .\DB_DeviceErrorLibrary.ps1

$RootCauseAdded = $false
Write-DiagProgress -activity $localizationString.Troubleshoot_DriverProblem

$ProblemDevice = Get-WmiObject -Class Win32_PnPEntity | Where-Object -FilterScript {$_.DeviceID -eq $DeviceID}

if(($ProblemDevice -ne $Null) -and ($ProblemDevice.ConfigManagerErrorCode -ne $Null))
{
    [string]$DeviceName = $ProblemDevice.Name
    [string]$ErrorCode = $ProblemDevice.ConfigManagerErrorCode

    if ([String]::IsNullOrEmpty($DeviceName))
    {
        $DeviceName = $localizationString.UnknownDevice
    }

    if($HashUpdateDriver.Contains($ErrorCode) -eq $True)
    {
        Update-DiagRootCause -id RC_DeviceDriverNeedUpdated -iid $DeviceID -Detected $true -p @{'DeviceName'= $DeviceName; 'DeviceID'= $DeviceID}
        $ProblemDevice | Select-Object -Property @{Name=$localizationString.DeviceName; Expression={$_.Name}}, @{Name=$localizationString.PnPDeviceID; Expression={$_.PNPDeviceID}}, @{Name=$localizationString.ConfigManagerErrorCode; Expression={$_.ConfigManagerErrorCode}} | ConvertTo-XML | Update-DiagReport -ID DriverProblem -Name $localizationString.Report_Name_ProblemDevice -Verbosity Informational -rid RC_DeviceDriverNeedUpdated -riid $DeviceID
        $RootCauseAdded = $True
    }
    else
    {
        if ($Action -eq "Verify")
        {
            Update-DiagRootCause -id RC_DeviceDriverNeedUpdated -iid $DeviceID -Detected $false -p @{'DeviceName'= $DeviceName; 'DeviceID'= $DeviceID}
        }
    }
}

return $RootCauseAdded
