# Copyright © 2008, Microsoft Corporation. All rights reserved.


#
#RS_DriverNotFound.ps1
#

PARAM($DeviceName, $DeviceID)

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.Resolution_DriverNotFound

#
#Get HardwareID for current problematic device
#
$ProblemDevice = Get-WmiObject -Class Win32_PnPEntity | Where-Object -FilterScript {$_.DeviceID -eq $DeviceID}
if(($ProblemDevice -eq $Null) -or ($ProblemDevice.HardwareID.Count -eq $Null) -or ($ProblemDevice.HardwareID.Count -eq 0))
{
    return
}
$ProblemHardwareID = $ProblemDevice.HardwareID

$TargetEvent = $Null
$DriverNotFoundEvents = GetEvent "application" "Windows Error Reporting" 1001
foreach($Event in $DriverNotFoundEvents)
{
    [string]$DeviceIDFromEvent = $Event.Properties[6].Value
    if([String]::IsNullOrEmpty($DeviceIDFromEvent) -eq $False)
    {
        foreach($ID in $ProblemHardwareID)
        {
            if([String]::Compare($DeviceIDFromEvent, $ID, $True) -eq 0)
            {
                $TargetEvent = $Event
                break
            }
        }
        if($TargetEvent -ne $Null)
        {
            break
        }
    }
}

if($TargetEvent -ne $Null)
{
    [string]$Platform = $TargetEvent.Properties[5].Value
    [string]$DeviceID = $TargetEvent.Properties[6].Value

    $QueryResult = QueryWERResponse $Platform $DeviceID

    if($QueryResult -ne $NULL)
    {
        if([String]::IsNullOrEmpty($QueryResult.responseUrl) -eq $True)
        {
            return
        }

        if([String]::IsNullOrEmpty($QueryResult.reportStoreLocation) -eq $True)
        {
            return
        }

        if($QueryResult.isResponseApplicable -eq $False)
        {
            return
        }

        Get-DiagInput -id IT_OpenPRSSolution -param @{'DeviceName'=$DeviceName; 'ReportLocation'=$QueryResult.reportStoreLocation; 'ReportType'=$QueryResult.reportStoreType}
    }
}