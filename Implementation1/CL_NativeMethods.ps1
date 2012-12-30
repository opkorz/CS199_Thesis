# Copyright © 2008, Microsoft Corporation. All rights reserved.

#requires -version 2.0

$source = @"
using System;
using System.ComponentModel;
using System.Text;
using System.Runtime.InteropServices;

namespace Microsoft.Windows.Diagnosis
{
    public static class NativeMethods
    {
        [DllImport("slc.dll", CharSet = CharSet.Auto)]
        static extern int SLGetWindowsInformationDWORD(String pwszValueName, out UInt32 pdwValue);

        [DllImport("shlwapi.dll")]
        static extern Boolean IsOS(UInt32 dwOS);

        public static Boolean SKUCanCreate()
        {
            UInt32 createEnabled = 0;
            SLGetWindowsInformationDWORD("provsvc-license-HomeGroupCreate", out createEnabled);
            return (createEnabled > 0);
        }

        public static Boolean IsDomainJoined()
        {
            UInt32 OS_DOMAINMEMBER = 28;
            return IsOS(OS_DOMAINMEMBER);
        }
    }

    // IID_ILocalPublishedMessages
    [ComImport]
    [Guid("2D22C347-EF2C-4C4A-9554-537307EDF8EC")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface ILocalPublishedMessages
    {
        void GetLocalPublishedItems([Out] IntPtr ppocPublishedItems);
        void RepublishItems([In] IntPtr pocPublishedItems);
        void RepublishItemsFromOfflineCache();
    }

    // CLSID_WSDPublisher
    [ComImport]
    [Guid("D7C1AEB5-10F2-48cb-A182-F7EF79C51B19")]
    internal class CWSDPublisher
    {
    }

    public static class WSDPublisher
    {
        public static void RepublishItemsFromOfflineCache()
        {
            ILocalPublishedMessages publisher = new CWSDPublisher() as ILocalPublishedMessages;
            publisher.RepublishItemsFromOfflineCache();
        }
    }
}
"@

Add-Type -TypeDefinition $source

function SKUCanCreate()
{
    return [Microsoft.Windows.Diagnosis.NativeMethods]::SKUCanCreate()
}

function IsDomainJoined()
{
    return [Microsoft.Windows.Diagnosis.NativeMethods]::IsDomainJoined()
}

function RepublishItemsFromOfflineCache()
{
    [Microsoft.Windows.Diagnosis.WSDPublisher]::RepublishItemsFromOfflineCache()
}