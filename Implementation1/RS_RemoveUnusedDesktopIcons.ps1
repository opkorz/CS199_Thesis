# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($unusedDesktopShortcuts)

. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.deleteUnusedDesktopShortcuts_progress

# Function to get file name by full path
function Get-FileName([string]$filePath = $(throw "No file path is specified"))
{
    if([String]::IsNullOrEmpty($filePath) -and (-not(Test-Path $filePath)))
    {
        throw "No file found"
    }

    return [System.IO.Path]::GetFileName($filePath)
}

# Function to get proper date format
function Format-Date($dateTime = $(throw "No date time is specified"))
{
    if($dateTime -eq $null)
    {
        throw "No date time found"
    }

    [string]$result = $dateTime.ToShortDateString()

    return $result
}

$choices = New-Object System.Collections.ArrayList
[string]$fileName = ""
$lastAccessTime = $null

Parse-List $unusedDesktopShortcuts | Where {Test-Path $_} | Foreach-Object {
    $fileName = Get-FileName $_
    $lastAccessTime = Format-Date (Get-LastAccessTime $_)
    $choices += Get-Choice ($fileName + " - " + $lastAccessTime) $fileName $_
}

[string]$deleteList = ""
(Get-DiagInput -id IT_GetUnusedIconsToCleanup -choice $choices) | Foreach-Object {
    if(-not([String]::IsNullOrEmpty($_)) -and (Test-Path $_))
    {

$deleteList = AttachTo-List $deleteList $_
    }
}

if(-not([String]::IsNullOrEmpty($deleteList)))
{
    Remove-FileList $deleteList
}
