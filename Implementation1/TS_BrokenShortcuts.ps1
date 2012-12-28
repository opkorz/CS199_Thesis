# Copyright © 2008, Microsoft Corporation. All rights reserved.

# Check broken shortcuts
. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

# Function to get a list of broken links
function Get-BrokenShortcutList([string]$path = $(throw "No path is specified"))
{
    [string]$list = ""
    Get-ChildItem -Path $path -filter *.lnk | Foreach-Object {
        $fullPath = ConvertTo-WQLPath $_.FullName
        $wmiLinkFile = Get-WmiObject -query "SELECT Name,Target,AccessMask FROM Win32_ShortcutFile WHERE Name = '$fullPath'"

        if(-not(Test-ValidLink $wmiLinkFile) -and (Test-Delete $wmiLinkFile))
        {
            $list = AttachTo-List $list $wmiLinkFile.Name
        }
    }

    return $list
}

[string]$desktopFolderPath = Get-DesktopPath
[string]$startupFolderPath = Get-StartupPath
[string]$brokenDesktopShortcuts = ""
[string]$brokenStartupShortcuts = ""

Write-DiagProgress -activity $localizationString.checkBrokenDesktopShortcuts_progress
$brokenDesktopShortcuts = Get-BrokenShortcutList $desktopFolderPath
if(-not([String]::IsNullOrEmpty($brokenDesktopShortcuts)))
{
    Parse-List $brokenDesktopShortcuts | Select-Object -Property @{Name=$localizationString.shortcutName;Expression={$_}} | ConvertTo-Xml | Update-DiagReport -id BrokenDesktopShortcutsList -Name $localizationString.brokenDesktopShortcuts_name -Description $localizationString.brokenDesktopShortcuts_description -Verbosity Informational -rid "RC_BrokenShortcuts"
}

Write-DiagProgress -activity $localizationString.checkBrokenStartupShortcuts_progress
$brokenStartupShortcuts = Get-BrokenShortcutList $startupFolderPath
if(-not([String]::IsNullOrEmpty($brokenStartupShortcuts)))
{
    Parse-List $brokenStartupShortcuts | Select-Object -Property @{Name=$localizationString.shortcutName;Expression={$_}}  | ConvertTo-Xml | Update-DiagReport -id BrokenStartupShortcutsList -Name $localizationString.brokenStartupShortcuts_name -Description $localizationString.brokenStartupShortcuts_description -Verbosity Informational -rid "RC_BrokenShortcuts"
}

if(-not([String]::IsNullOrEmpty($brokenDesktopShortcuts) -and [String]::IsNullOrEmpty($brokenStartupShortcuts)) -and (((Get-ListLength $brokenDesktopShortcuts) + (Get-ListLength $brokenStartupShortcuts)) -gt 4))
{
    Update-DiagRootCause -id "RC_BrokenShortcuts" -Detected $true -parameter @{'BrokenDesktopShortcuts'=$brokenDesktopShortcuts;'BrokenStartupShortcuts'=$brokenStartupShortcuts}
} else {
    Update-DiagRootCause -id "RC_BrokenShortcuts" -Detected $false -parameter @{'BrokenDesktopShortcuts'=$brokenDesktopShortcuts;'BrokenStartupShortcuts'=$brokenStartupShortcuts}
}
