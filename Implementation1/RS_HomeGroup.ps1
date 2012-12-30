# Copyright © 2008, Microsoft Corporation. All rights reserved.

PARAM($printerName)
#
# Share the specified printer
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
Write-DiagProgress -activity $localizationString.progress_rs_homeGroup

. .\CL_Utility.ps1

[int]$PRINTER_ATTRIBUTE_SHARED = 0x00000008
SetPrinterAttributes $printerName $PRINTER_ATTRIBUTE_SHARED