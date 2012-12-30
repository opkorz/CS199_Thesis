# Copyright © 2008, Microsoft Corporation. All rights reserved.

function IsWUBlocked
{
    $GPSetting = Get-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -ErrorAction SilentlyContinue

    if (($GPSetting -eq $null) -or ($GPSetting.SearchOrderConfig -eq $null)) {
        $Setting = Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -ErrorAction SilentlyContinue

        if (($Setting -eq $null) -or ($Setting.SearchOrderConfig -eq $null)) {
            return $true
        }

        return ($Setting.SearchOrderConfig -eq "0")
    }

    return ($GPSetting.SearchOrderConfig -eq "0")
}

$WUBlocked = IsWUBlocked
Update-DiagRootCause -id RC_WindowsUpdate -Detected $WUBlocked

