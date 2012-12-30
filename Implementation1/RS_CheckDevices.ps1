# Copyright © 2008, Microsoft Corporation. All rights reserved.


#RS_CheckDevices.ps1
PARAM($DeviceName, $DeviceID, $ErrorCode)

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

. .\CL_Utility.ps1
. .\DB_DeviceErrorLibrary.ps1

$Title = $localizationString.Title_Default

if ($HashTitle.Contains($ErrorCode) -eq $True)
{
    $Title = $HashTitle.Get_Item($ErrorCode)
}

$Title = $Title.Replace("%DEVICENAME%", $DeviceName)

$Hint = ""

if ($HashHint.Contains($ErrorCode) -eq $True)
{
    $Hint = $HashHint.Get_Item($ErrorCode)
}

$WizardChoice = Get-DiagInput -ID "IT_OpenProblemWizard" -Parameter @{'DeviceName'= $DeviceName;'DeviceID' = $DeviceID;'Title' = $Title;'Hint' = $Hint}
