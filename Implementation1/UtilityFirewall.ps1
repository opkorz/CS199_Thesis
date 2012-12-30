# Copyright © 2008, Microsoft Corporation. All rights reserved.

#This script adds the necessary interop interfaces to query the system for firewall drops

$FWAPISource = @"

using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
using System.Collections;

namespace Microsoft.Windows.Diagnosis.FirewallAPI
{

    [StructLayout(LayoutKind.Sequential)]
    public struct FW_DIAG_APP
    {
        [MarshalAs(UnmanagedType.LPWStr)]
        public string AppPath;
    }

    [Flags]
    internal enum AssocF
    {
        Init_NoRemapCLSID = 0x1,
        Init_ByExeName = 0x2,
        Open_ByExeName = 0x2,
        Init_DefaultToStar = 0x4,
        Init_DefaultToFolder = 0x8,
        NoUserSettings = 0x10,
        NoTruncate = 0x20,
        Verify = 0x40,
        RemapRunDll = 0x80,
        NoFixUps = 0x100,
        IgnoreBaseClass = 0x200
    }

    [Flags]
    internal enum AssocStr
    {
        Command = 1,
        Executable,
        FriendlyDocName,
        FriendlyAppName,
        NoOpen,
        ShellNewValue,
        DDECommand,
        DDEIfExec,
        DDEApplication,
        DDETopic
    }

    internal enum FW_STORE_TYPE
    {
        FW_STORE_TYPE_INVALID,
        FW_STORE_TYPE_GP_RSOP,      //read-only
        FW_STORE_TYPE_LOCAL,
        FW_STORE_TYPE_WSH_STATIC,   //read-only
        FW_STORE_TYPE_WSH_CONFIGURABLE,
        FW_STORE_TYPE_DYNAMIC,
        FW_STORE_TYPE_GPO,
        FW_STORE_TYPE_DEFAULTS,
        FW_STORE_TYPE_MAX
    }

    internal enum FW_POLICY_ACCESS_RIGHT
    {
        FW_POLICY_ACCESS_RIGHT_INVALID,
        FW_POLICY_ACCESS_RIGHT_READ,
        FW_POLICY_ACCESS_RIGHT_READ_WRITE,
        FW_POLICY_ACCESS_RIGHT_MAX
    }

    [Flags]
    internal enum FW_POLICY_STORE_FLAGS
    {
        FW_POLICY_STORE_FLAGS_NONE = 0x0000,
        FW_POLICY_STORE_FLAGS_DELETE_DYNAMIC_RULES_AFTER_CLOSE = 0x0001,
        FW_POLICY_STORE_FLAGS_MAX = 0x0002
    };

    internal class NativeMethods
    {

        public const ushort FW_CURRENT_BINARY_VERSION = 0x20A;

        [DllImport("Shlwapi.dll", SetLastError = false, CharSet = CharSet.Unicode)]
        public static extern uint AssocQueryString(
                            AssocF flags,
                            AssocStr str,
                            string pszAssoc,
                            string pszExtra,
                            [Out]StringBuilder pszOut,
                            [In][Out] ref uint pcchOut
                            );

        [DllImport("FirewallAPI.dll", CharSet = CharSet.Unicode)]
        public static extern uint FWOpenPolicyStore(
                                        ushort wBinaryVersion,
                                        string wszMachineOrGPO,  // Object to connect to - machine name or GPO path (NULL for local machine)
                                        FW_STORE_TYPE StoreType,
                                        FW_POLICY_ACCESS_RIGHT AccessRight,
                                        FW_POLICY_STORE_FLAGS dwFlags, // Bit-flags from FW_POLICY_STORE_FLAGS
                                        out IntPtr phPolicy
                                        );


        [DllImport("FirewallAPI.dll")]
        public static extern uint FWClosePolicyStore(IntPtr hPolicy);

        [DllImport("FirewallAPI.dll")]
        public static extern uint FWDiagGetAppList(
                                IntPtr hPolicy,
                                ref uint pcchOut,
                                ref IntPtr DiagApps
                                );
        [DllImport("FirewallAPI.dll")]
        public static extern void FWFreeDiagAppList(IntPtr DiagApps);

    }

    public class DiagAppInfo
    {

        public DiagAppInfo(string friendlyName, string path)
        {
            FriendlyName = friendlyName;
            Path = path;
        }

        public string FriendlyName
        {
            get
            {
                return this._friendlyName;

            }
            set
            {
                this._friendlyName = value;
            }
        }

        public string Path
        {
            get
            {
                return this._path;

            }
            set
            {
                this._path = value;
            }
        }



        private string _friendlyName;
        private string _path;

    }

    public class ManagedMethods
    {

        public static List<FW_DIAG_APP> GetFwDiagApps()
        {
            IntPtr StoreHandle = IntPtr.Zero;
            uint AppCount = 0;
            IntPtr AppList = IntPtr.Zero;
            IntPtr AppListIter = IntPtr.Zero;
            FW_DIAG_APP app;
            List<FW_DIAG_APP> appList = new List<FW_DIAG_APP>();

            uint res = NativeMethods.FWOpenPolicyStore(
                                NativeMethods.FW_CURRENT_BINARY_VERSION,
                                null,
                                FW_STORE_TYPE.FW_STORE_TYPE_DYNAMIC,
                                FW_POLICY_ACCESS_RIGHT.FW_POLICY_ACCESS_RIGHT_READ,
                                FW_POLICY_STORE_FLAGS.FW_POLICY_STORE_FLAGS_NONE,
                                out StoreHandle
                                );

            if (0 != res)
            {
		throw new System.ComponentModel.Win32Exception((Int32)res);
            }
            else
            {
                res = NativeMethods.FWDiagGetAppList(
                            StoreHandle,
                            ref AppCount,
                            ref AppList
                            );

                if (res != 0)
                {
                    throw new System.ComponentModel.Win32Exception((Int32)res);
                }
                else
                {
                    if (AppCount > 0)
                    {
                        AppListIter = AppList;

                        for (uint i = 0; i < AppCount; i++)
                        {

                            app = (FW_DIAG_APP)Marshal.PtrToStructure(
                                                            AppListIter,
                                                            typeof(FW_DIAG_APP)
                                                            );
                            appList.Add(app);
                            AppListIter = new IntPtr(AppListIter.ToInt64() + IntPtr.Size);

                        }

                        NativeMethods.FWFreeDiagAppList(AppList);
                    }
                }
                NativeMethods.FWClosePolicyStore(StoreHandle);
            }

            return appList;
        }

        public static bool AppAlreadyExists(FW_DIAG_APP app, List<DiagAppInfo> DiagAppInfoList)
        {

            foreach (DiagAppInfo appInfo in DiagAppInfoList)
            {
                if (0 == string.Compare(appInfo.Path, app.AppPath, true))
                {
                    return true;
                }
            }
            return false;
        }

        public static string GetFriendlyName(string appPath)
        {

            uint uSize = 0;
            uint uRet = 0;
            string friendlyName = null;

            NativeMethods.AssocQueryString(
                                 AssocF.Open_ByExeName,
                                 AssocStr.FriendlyAppName,
                                 appPath,
                                 null,
                                 null,
                                 ref uSize
                                 );

            StringBuilder pszOut = new StringBuilder((int)uSize);

            uRet = NativeMethods.AssocQueryString(
                            AssocF.Open_ByExeName,
                            AssocStr.FriendlyAppName,
                            appPath,
                            null,
                            pszOut,
                            ref uSize
                            );

            if (0 == uRet)
            {
                friendlyName = pszOut.ToString();
            }

            if (null == friendlyName)
            {
                friendlyName = System.IO.Path.GetFileNameWithoutExtension(appPath);
            }

            return friendlyName;
        }

        public static List<DiagAppInfo> GetDiagAppInfo()
        {

            List<FW_DIAG_APP> fwAppInfoList = GetFwDiagApps();
            List<DiagAppInfo> diagAppInfoList = new List<DiagAppInfo>();
            string friendlyName = null;

            foreach (FW_DIAG_APP app in fwAppInfoList)
            {
                if (AppAlreadyExists(app, diagAppInfoList))
                {
                    continue;
                }

                friendlyName = GetFriendlyName(app.AppPath);

                diagAppInfoList.Add(new DiagAppInfo(friendlyName, app.AppPath));
            }

            return diagAppInfoList;
        }

    }
}
"@

$type = Add-Type -TypeDefinition $FWAPISource

