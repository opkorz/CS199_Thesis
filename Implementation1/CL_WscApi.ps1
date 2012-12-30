# Copyright © 2008, Microsoft Corporation. All rights reserved.


$source = @"
using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
using System.Management;
using System.Reflection;

namespace Microsoft.Windows.Diagnosis
{
    public class WscApi
    {
        private const uint c_ProductStateMask          = 0x0000f000;
        private const uint c_ProductOwnerMask          = 0x00000f00;
        private const uint c_ProductStatusMask         = 0x000000f0;
        private const uint c_LegacyProductStateMask    = 0x0000000f;

        [DllImport("wscapi.dll", CharSet = CharSet.Auto)]
        private static extern int wscFirewallGetStatus(
                                      out uint numProducts,
                                      out IntPtr productInfoPtr);

        [DllImport("wscapi.dll", CharSet = CharSet.Auto)]
        private static extern void wscProductInfoFree(
                                      uint numProducts,
                                      IntPtr productInfoPtr);

        public static uint GetFirewallCount()
        {
            IntPtr productInfoPtr;
            uint numProducts;

            wscFirewallGetStatus(out numProducts, out productInfoPtr);

            wscProductInfoFree(numProducts, productInfoPtr);
            return numProducts;
        }

        public static List<ProductInfo> GetFirewalls()
        {
            IntPtr productInfoPtr;
            uint numProducts;
            List<ProductInfo> list = new List<ProductInfo>();

            wscFirewallGetStatus(out numProducts, out productInfoPtr);

            if (numProducts > 0)
            {
                IntPtr iter = productInfoPtr;
                ProductInfo info;
                for (uint i = 0; i < numProducts; i++)
                {
                    info = (ProductInfo)Marshal.PtrToStructure(iter, typeof(ProductInfo));
                    iter = (IntPtr)((int)iter + Marshal.SizeOf(typeof(ProductInfo)));
                    list.Add(info);
                }
            }
            wscProductInfoFree(numProducts, productInfoPtr);
            return list;
        }

        public static LegacyProductState GetLegacyProductState(uint productBitFields)
        {
            return (LegacyProductState)(c_LegacyProductStateMask & productBitFields);
        }

        public static LegacyProductState GetLegacyProductState(ProductInfo info)
        {
            return GetLegacyProductState(info.ProductBitFields);
        }

        public static ProductOwner GetProductOwner(ProductInfo info)
        {
            return (ProductOwner)(c_ProductOwnerMask & info.ProductBitFields);
        }

        public static ProductState GetProductState(ProductInfo info)
        {
            return (ProductState)(c_ProductStateMask & info.ProductBitFields);
        }

        public static ProductStatus GetProductStatus(ProductInfo info)
        {
            return (ProductStatus)(c_ProductStatusMask & info.ProductBitFields);
        }
    }

    // The following 3 fields of this enum, has to match in order with the
    // actual product enum in "public\internal\admin\inc\wscsvc.h"
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct ProductInfo
    {
        public uint ProductBitFields;
        public string ProductName;
        public string ProductPath;
        public string BitsToString()
        {
            return String.Format("{0}, {1}, {2}",
                WscApi.GetProductState(this).ToString(),
                WscApi.GetProductStatus(this).ToString(),
                WscApi.GetProductOwner(this).ToString());

        }
    }

    public enum HealthStatus
    {
        Green, Yellow, Red, Snoozed
    }

    [Flags]
    public enum LegacyProductState
    {
        Enabled     = 0x1,
        UpToDate    = 0x2,
        Microsoft   = 0x4
    }

    public enum ProductStatus
    {
        UpToDate     = 0x00,
        OutOfDate    = 0x10
    }

    public enum ProductOwner
    {
        NonMs        = 0x000,
        Windows      = 0x100
    }

    public enum ProductState
    {
        Off         = 0x0000,
        Enabled     = 0x1000,
        Snoozed     = 0x2000
    }
}
"@

Add-Type -TypeDefinition $source

function Check-Firewall([ref]$FirewallName)
{
    [bool]$issueDetected = $false
    $firewalls = [Microsoft.Windows.Diagnosis.WscApi]::GetFirewalls()

    foreach ($fw in $firewalls)
    {
        $owner = [Microsoft.Windows.Diagnosis.WscApi]::GetProductOwner($fw)
        if ($owner -ne [Microsoft.Windows.Diagnosis.ProductOwner]::Windows)
        {
            $state = [Microsoft.Windows.Diagnosis.WscApi]::GetProductState($fw)
            if ($state -eq [Microsoft.Windows.Diagnosis.ProductState]::Enabled)
            {
                $issueDetected = $true
                $FirewallName.Value = $fw.ProductName
                break
            }
        }
    }
    return $issueDetected
}