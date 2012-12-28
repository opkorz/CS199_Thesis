# Copyright © 2008, Microsoft Corporation. All rights reserved.

. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.checkVolumeErrors_progress

# Function to check whether volume is dirty
function Test-VolumeDirty([string]$volumeName = $(throw "No volume name is specified"))
{
    [bool]$result = $false

[string]$typeDefinition = @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
using System.ComponentModel;

namespace Microsoft.Chkdsk
{
    internal static class NativeMethods
    {
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern SafeFileHandle CreateFile(
            string lpFileName, int dwDesiredAccess, int dwShareMode, IntPtr lpSecurityAttributes, int dwCreationDisposition, int dwFlagsAndAttributes, IntPtr hTemplateFile);

        [DllImport("Kernel32.dll", CharSet = CharSet.Auto)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool DeviceIoControl(
            SafeFileHandle hDevice, int IoControlCode, IntPtr InBuffer, int nInBufferSize, out int lpOutBuffer, int nOutBufferSize, out int pBytesReturned, IntPtr Overlapped);
    }

    public static class ChkdskDirty
    {
        private const int GENERIC_READ = -2147483648;
        private const int FILE_SHARE_READ = 0x00000001;
        private const int FILE_SHARE_WRITE = 0x00000002;
        private const int OPEN_EXISTING = 3;
        private const int FILE_ATTRIBUTE_NORMAL = 0x00000080;
        private const int FSCTL_IS_VOLUME_DIRTY = 589944;
        private const int VOLUME_IS_DIRTY = 1;

        public static bool IsVolumeDirty(string volumeName)
        {
            string FileName = @"\\.\" + volumeName;
            int VolumeStatus;
            int pBytesReturned;

            using (SafeFileHandle FileHandle = NativeMethods.CreateFile(FileName, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, IntPtr.Zero, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, IntPtr.Zero))
            {
                if (FileHandle.IsInvalid)
                {
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                }

                if (!NativeMethods.DeviceIoControl(FileHandle, FSCTL_IS_VOLUME_DIRTY, IntPtr.Zero, 0, out VolumeStatus, sizeof(int), out pBytesReturned, IntPtr.Zero))
                {
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                }
            }

            return (VolumeStatus & VOLUME_IS_DIRTY) == VOLUME_IS_DIRTY;
        }
    }
}
"@
    $type = Add-Type -TypeDefinition $typeDefinition -PassThru
    if($type[1]::IsVolumeDirty($volumeName))
    {
        $result = $true
    }

    return $result
}

[string]$query = "Select DeviceID from win32_logicalDisk WHERE MediaType=12"
$devices = (Get-WmiObject -query $query)
if($devices -ne $null) {
    foreach($device in $devices) {
        if(Test-VolumeDirty $device.DeviceId)
        {
             Update-DiagRootCause -id "RC_VolumeErrors" -Detected $true

             return
        }
    }
}

Update-DiagRootCause -id "RC_VolumeErrors" -Detected $false

