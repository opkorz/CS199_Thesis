# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($brokenDesktopShortcuts, $brokenStartupShortcuts)

. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.DeleteBrokenDesktopShortcuts_progress

Remove-FileList $brokenDesktopShortcuts

Write-DiagProgress -activity $localizationString.DeleteBrokenStartupShortcuts_progress

Remove-FileList $brokenStartupShortcuts
