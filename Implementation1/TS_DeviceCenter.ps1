# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_Utility.ps1
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.Progress_Troubleshoot

try
{
    [string]$DeviceErrorInfo = Get-DiagInput -ID "IT_DeviceInfo"
}
catch
{
    return
}

if([String]::IsNullOrEmpty($DeviceErrorInfo) -eq $True)
{
    return
}

$DeviceDataArray = GetProblematicFunctionForObject $DeviceErrorInfo

###################Test Cast -- PnPDevice#################################
#$DeviceData = New-Object System.Collections.ArrayList
#$DeviceData += "PNPDevice"
#$DeviceData += "IDE\CDROMHL-DT-ST_DVD-ROM_GDRH20N________________0D04____\5&22F68978&0&1.0.0"
#############################################################

###################Test Cast -- Printer#################################
#$DeviceData = New-Object System.Collections.ArrayList
#$DeviceData += "Printer"
#$DeviceData += "Default"
#############################################################


if($DeviceDataArray -eq $Null)
{
    return
}

$PnPDeviceID = ""
$PrinterName = ""

foreach($DeviceData in $DeviceDataArray)
{
    $DeviceType = $DeviceData.Type

    if([String]::IsNullOrEmpty($DeviceType) -eq $True)
    {
        return
    }

    if($DeviceType -eq "PNPDevice")
    {
        $PnPDeviceID += $DeviceData.DeviceID
        $PnPDeviceID += "#"
    }

    if($DeviceType -eq "Printer")
    {
        $PrinterName = $DeviceData.DeviceName
    }
}


if([String]::IsNullOrEmpty($PnPDeviceID) -eq $False)
{
    $PnPDeviceID = $PnPDeviceID.Replace("&", "&amp;")
    Update-DiagRootCause -id "RC_ProblematicPNPDevice" -Detected $true -p @{'DEVICEID' = $PnPDeviceID}
}


if([String]::IsNullOrEmpty($PrinterName) -eq $False)
{
    Update-DiagRootCause -id "RC_ProblematicPrinter" -Detected $true -p @{'PRINTERNAME' = $PrinterName}
}
