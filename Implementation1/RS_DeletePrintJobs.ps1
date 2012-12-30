# Copyright © 2008, Microsoft Corporation. All rights reserved.


#
# Deleting *.spl and *.shd files will remove all jobs from the printer queue
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1

Write-DiagProgress -activity $localizationString.progress_rs_deletePrintJobs

[string]$directory = GetSystemPath "\spool\printers"
$printFiles = Get-ChildItem $directory | where-object -FilterScript { $_.Extension -eq ".spl" -or $_.Extension -eq ".shd" }

if($printFiles -eq $null)
{
    return
}

[string]$faxStatus = (Get-Service Fax).Status
try
{
    Stop-Service Spooler -Force
    WaitFor-ServiceStatus "Spooler" ([ServiceProcess.ServiceControllerStatus]::Stopped)

    $printFiles | foreach { Remove-Item $_.FullName }
}
finally
{
    Start-Service Spooler
    WaitFor-ServiceStatus "Spooler" ([ServiceProcess.ServiceControllerStatus]::Running)
    if($faxStatus -eq "Running")
    {
        Start-Service Fax
        WaitFor-ServiceStatus "Fax" ([ServiceProcess.ServiceControllerStatus]::Running)
    }
}
#
# update report
#

$notDeletedFiles = Get-ChildItem $directory | where-object -FilterScript { $_.Extension -eq ".spl" -or $_.Extension -eq ".shd" }

$deletedFileNames = New-Object System.Collections.ArrayList
$notDeletedFileNames = New-Object System.Collections.ArrayList

if($notDeletedFiles -eq $null)
{
    foreach($file in $printFiles)
    {
        $deletedFileNames += $file.Name
    }
}
else
{
    foreach($file in $printFiles)
    {
        [bool]$notDeleted = $false
        foreach($notDeletedfile in $notDeletedFiles)
        {
            if($file.Name -eq $notDeletedFile.Name)
            {
                $notDeleted = $true
                break
            }
        }
        if($notDeleted)
        {
            $notDeletedFileNames += $file.Name
        }
        else
        {
            $deletedFileNames += $file.Name
        }
    }
}

if($deletedFileNames.Length -gt 0)
{
    $deletedFileNames | select-object -Property @{Name=$localizationString.fileName; Expression={$_}} | convertto-xml | Update-DiagReport -id DeletedFiles -name $localizationString.deletedFiles_name -verbosity Informational
}

if($notDeletedFileNames.Length -gt 0)
{
    $notDeletedFileNames | select-object -Property @{Name=$localizationString.fileName; Expression={$_}} | convertto-xml | Update-DiagReport -id CannotDeletedFiles -name $localizationString.cannotDeletedFiles_name -description $localizationString.cannotDeletedFiles_description -verbosity Informational
}
