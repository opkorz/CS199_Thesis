# Copyright © 2008, Microsoft Corporation. All rights reserved.


#CL_DetectingDevice
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

. .\DB_DeviceErrorLibrary.ps1

function DetectingDeviceFromPnPEntity()
{
    $HashRootCausesTable = New-Object System.Collections.HashTable
    if($HashRootCausesTable -eq $Null)
    {
        return $False
    }

    $PnPObjects = Get-WmiObject -Class Win32_PnPEntity

    foreach($DeviceItem in $PnPObjects)
    {
        [string]$DeviceName = $DeviceItem.Name
        [string]$DeviceID = $DeviceItem.PNPDeviceID
        [string]$DeviceErrorCode = $DeviceItem.ConfigManagerErrorCode

        if(($DeviceName -eq $Null) -or ($DeviceID -eq $Null) -or ($DeviceErrorCode -eq $Null))
        {
            continue
        }

        if($DeviceID -eq "")
        {
            continue
        }

        if($DeviceErrorCode -ne "0")
        {
            if($HashRootCausesTable.Contains($DeviceID) -eq $False)
            {
                $HashRootCausesTable.Add($DeviceID, $DeviceID)
            }
        }
    }

    return $HashRootCausesTable
}
