# Copyright © 2008, Microsoft Corporation. All rights reserved.


#RS_InstallDrivers.ps1
PARAM($DeviceName, $DeviceID)

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.Resolution_UpdateDriver

ReinstallDevice $DeviceID