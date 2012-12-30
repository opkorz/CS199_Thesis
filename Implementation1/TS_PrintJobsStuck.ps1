# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($printerName)
#
# check the current user's print jobs of the printer user selected. If these jobs exists, print jobs are stuck
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_ts_printJobsStuck

#
# Get the printer API
#
$winSpoolType = GetPrinterType
#
# Assume the print jobs's maximum is 99
#
[int]$MAX_PRINT_JOB = 99

#
# Specifies the type of job information as JOB_INFO_2
#
[int]$JOB_LEVEL = 2

#
# The API SetJob's parameter that show the print job will be deleted.
#
[int]$JOB_STATUS_PAUSED = 0x00000001
[int]$JOB_STATUS_ERROR = 0x00000002
[int]$JOB_STATUS_DELETING = 0x00000004
[int]$JOB_STATUS_BLOCKED_DEVQ = 0x00000200
[int]$JOB_STATUS_USER_INTERVENTION = 0x00000400

$JOB_INFO_2 = New-Object $winSpoolType[2]

[string]$fileName = "RS_PrinterJobsStuck"


[IntPtr]$hPrinter = [IntPtr]::Zero

#
# Opens the printer and gets the its handle
#
[int]$result = $winSpoolType[0]::OpenPrinter($printerName, [ref]$hPrinter, [IntPtr]::Zero)
[int]$errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
if($result -eq 0)
{
    WriteFileAPIExceptionReport $fileName "OpenPrinter" $errorCode
    return
}

try
{
    [IntPtr]$pJob =  [IntPtr]::Zero
    [int]$pcbneeded = 0
    [int]$pcReturned = 0

    #
    # Calls the EnumJobs and get necessary buffer from the parameter of pcbneeded
    #
    $result = $winSpoolType[0]::EnumJobs($hPrinter, 0, $MAX_PRINT_JOB, $JOB_LEVEL, $pJob, 0, [ref]$pcbneeded, [ref]$pcReturned)

    $reportJobs = New-Object System.Collections.ArrayList

    if($pcbneeded -gt 0)
    {
        $pJob = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($pcbneeded)
        try
        {
            #
            # Calls the EnumJobs to get the JOB_INFO_2 array into $pJob
            #
            $result = $winSpoolType[0]::EnumJobs($hPrinter, 0, $MAX_PRINT_JOB, $JOB_LEVEL, $pJob, $pcbneeded, [ref]$pcbneeded, [ref]$pcReturned)
            $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            if($result -eq 0)
            {
                WriteFileAPIExceptionReport $fileName "EnumJobs" $errorCode
                return
            }

            #
            # To every job, call the API of SetJob to delete it.
            #
            [int]$ptr = $pJob.ToInt32()
            for([int]$i = 0; $i -lt $pcReturned; $i++)
            {
                $pinfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, $JOB_INFO_2.GetType())

                if($pinfo.Status -band $JOB_STATUS_PAUSED -or $pinfo.Status -band $JOB_STATUS_ERROR -or $pinfo.Status -band $JOB_STATUS_DELETING -or $pinfo.Status -band $JOB_STATUS_BLOCKED_DEVQ -or $pinfo.Status -band $JOB_STATUS_USER_INTERVENTION)
                {
                    $reportJobs += $pinfo
                }
                $ptr += [System.Runtime.InteropServices.Marshal]::SizeOf($JOB_INFO_2.GetType())
            }
        }
        finally
        {
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($pJob)
        }
    }
}
finally
{
    $winSpoolType[0]::ClosePrinter($hPrinter) > $null
}

if($reportJobs.Count -gt 0)
{
    Update-DiagRootCause -id "RC_PrintJobsStuck" -Detected $true -parameter @{ "PRINTERNAME" = $printerName}
    $reportJobs | select-object -Property @{Name=$localizationString.printJobs_printerName; Expression={$_.pPrinterName}}, @{Name=$localizationString.printJobs_userName; Expression={$_.pUserName}}, @{Name=$localizationString.printJobs_status; Expression={$_.Status}} | convertto-xml | Update-DiagReport -id PrintJobs -name $localizationString.printJobs_name -verbosity Informational -rid "RC_PrintJobsStuck"
} else {
    Update-DiagRootCause -id "RC_PrintJobsStuck" -Detected $false -parameter @{ "PRINTERNAME" = $printerName}
}
