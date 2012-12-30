# Copyright © 2008, Microsoft Corporation. All rights reserved.


#TS_HardwareDevice
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

. .\CL_DetectingDevice.ps1

[String]$SelectResult = "None"

try
{
    $SelectResult = Get-DiagInput -id "IT_SelectDevice"
}
catch
{
    $SelectResult = "None"
}

if ($SelectResult -eq "ScanOnly") {
    Update-DiagRootCause -id RC_RescanAllDevices -Detected $true
    return
}

$DriverProblem = $false
$PNPDeviceArray = $Null
$HashRootCausesTable = $Null

if($SelectResult -ne "None")
{
    $PNPDeviceArray = $SelectResult.Split("#")
    $HashRootCausesTable = New-Object System.Collections.HashTable

    foreach ($DeviceID in $PNPDeviceArray)
    {
        if (-not [String]::IsNullOrEmpty($DeviceID)) {
            $HashRootCausesTable.Add($DeviceID, $DeviceID)
        }
    }
}
else
{
    $HashRootCausesTable = DetectingDeviceFromPnPEntity
}

foreach($DeviceID in $HashRootCausesTable.Values)
{
    $IsDriverNotFound = .\TS_DriverNotFound.ps1 $DeviceID
    if($IsDriverNotFound -eq $True)
    {
        $DriverProblem = $true
        continue
    }

    $IsDisabled = .\TS_DeviceDisabled.ps1 $DeviceID
    if($IsDisabled -eq $True)
    {
        continue
    }

    $IsDriverNeedUpdated = .\TS_DriverNeedUpdated.ps1 $DeviceID
    if($IsDriverNeedUpdated -eq $True)
    {
        $DriverProblem = $true
        continue
    }

    $IsNotWorkProperly = .\TS_NotWorkProperly.ps1 $DeviceID
}

if (($SelectResult -eq "None") -or ($DriverProblem -eq $true))
{
    .\TS_WindowsUpdate.ps1
}

if($SelectResult -eq "None")
{
    Update-DiagRootCause -id RC_RescanAllDevices -Detected $true
}
