# Copyright © 2008, Microsoft Corporation. All rights reserved.

PARAM($printerName)
#
# Check the default printer
# The root cause will be caught if the default printer is not the diagnosed printer..
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_ts_defaultPrinter

$defaultPrinter = Get-WmiObject -query "Select * From Win32_Printer Where default=true"

#
# The root cause will be caught if at least one physical printer is already installed and the default printer is not a physical printer.
#
if($defaultPrinter -eq $null -or $defaultPrinter.Name -ne $printerName)
{
    Update-DiagRootCause -id "RC_WrongDefaultPrinter" -Detected $true  -parameter @{ "PRINTERNAME" = $printerName}
} else {
    Update-DiagRootCause -id "RC_WrongDefaultPrinter" -Detected $false  -parameter @{ "PRINTERNAME" = $printerName}
}
