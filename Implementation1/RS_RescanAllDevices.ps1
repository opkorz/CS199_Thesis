# Copyright © 2008, Microsoft Corporation. All rights reserved.


#
#RS_RescanAllDevices.ps1
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.Resolution_RescanAllDevices

$Rescan = RescanAllDevices
