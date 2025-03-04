#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2025 Advanced Micro Devices, Inc.
# @Author(s): Kalpana Shetty <Kalpana.Shetty@amd.com>
#             Babu Moger <Babu.Moger@amd.com>
# @Module Name: qos.py
# @Description: Covers tests with CPUID feature check and MSR check tests
# @History:  Created Jan 10 2025 - Created

import sys
import subprocess
from subprocess import Popen, PIPE
import os.path
from lib.qos_common import CommonLib
from avocado import Test

cpuidDatahex = ""
cpuidData = ""
MSRDict = {}
RWDict = {}
ValueDict = {}
MSRAddr = []

# Constants
PQOS_CPUID =        "0x00000007 0x00"
L3CACHE_MON_CPUID = "0x0000000f 0x00"
L3CACHE_MON1_CPUID = "0x0000000f 0x01"
CAPMASKLEN_CPUID = "0x80000020 0x01"
L3CACHE_ALLOC_CPUID = "0x00000010 0x00"
BANDWIDTH_ENFORCE_CPUID = "0x80000008 0x00"

class Pqos(Test):
    def test_CPUID(self):
        self.log.info(" -- Testing the PQOS CPUID features --")
        """
        Feature availability check using cpuid
        """
        comm = CommonLib()
        code, out, err = comm.Run("cpuid -1 -r")
        cpuidDatahex = out.split('\n')

        for line in cpuidDatahex:
            # CPUID function 7 Indicates the overall support for Platform QOS Monitoring
            # CPUID EAX 0x7h, ECX=0: PQM - EBX bit 12; PQE - EBX bit 15
            if PQOS_CPUID in line:
                regs = line.split(" ")
                pqm = int(regs[6][6:14], 16)

                #Check PQM feature in CPUID.(EAX=07H, ECX=00H):EBX.[bit 12]
                if (pqm & 0x1000):
                    self.log.info("PASS: Platform QOS Monitoring feature Supported!\n")
                else:
                    self.log.info("CANCEL: Platform QOS Monitoring feature Unsupported!")

                #Check PQM feature in CPUID.(EAX=07H, ECX=00H):EBX.[bit 15]
                if (pqm & 0x8000):
                    self.log.info("PASS: Platform QOS Enforcement feature Supported!\n")
                else:
                    self.log.info("CANCEL: Platform QOS Enforcement feature Unsupported!\n")

            # CPUID EAX 0xFh, ECX=0: L3CacheMon - EDX, bit 1, RMID MAX - EBX, bits 0..31
            if L3CACHE_MON_CPUID in line:
                regs = line.split(" ")
                l3cache_mon = int(regs[8][6:14], 16)

                if (l3cache_mon & 0x2):
                    self.log.info("PASS: L3 Cache Monitoring Supported!\n")
                else:
                    self.log.info("CANCEL: L3 Cache Monitoring Supported!\n")

                rmid_max = int(regs[6][6:14], 16)
                if (rmid_max & 0xff):
                    self.log.info("PASS: Largest RMID supported by the system for any resource = %d" % rmid_max)
                else:
                    self.log.info("CANCEL: Unable to get Largest RMID")

            # CPUID EAX 0xFh, ECX=1: ConvertFactor - EBX, bits 0..31, L3Cache RMID Max - ECX, bits 0..31
            #                        L3CacheOccMon - EDX, bit 0, L3CacheTotBWMon: EDX, bit 1
            #                        L3CacheLclBWMon - EDX, bit 2
            if L3CACHE_MON1_CPUID in line:
                regs = line.split(" ")
                ConvertFactor = int(regs[6][6:14], 16)
                if (ConvertFactor):
                    self.log.info("PASS: L3 Cache Conversion Factor Value = 0x%x" % ConvertFactor)
                else:
                    self.log.info("CANCEL: L3 Cache Conversion Factor Not Set")
                RMID_L3 = int(regs[7][6:14], 16)
                if (RMID_L3 & 0xFF):
                    self.log.info("PASS: RMID L3 Cache Set")
                else:
                    self.log.info("CANCEL: RMID L3 Cache Unset")

                L3CacheMon = int(regs[8][6:14], 16)
                if (L3CacheMon & 0x1):
                    self.log.info("PASS: L3 Cache Occupancy Monitoring Supported")
                else:
                    self.info("CANCEL: L3 Cache Occupancy Monitoring Unsupported")

                if (L3CacheMon & 0x2):
                    self.log.info("PASS: L3 Cache Total Bandwidth Monitoring Supported")
                else:
                    self.log.info("CANCEL: L3 Cache Total Bandwidth Monitoring Unset")

                if (L3CacheMon & 4):
                    self.log.info("PASS: L3 Cache Local Bandwidth Monitoring Supported")
                else:
                    self.log.info("CANCEL: L3 Cacne Local Bandwidth Monitoring Unsupported")

            # CPUID EAX=0x80000020h, ECX=1: CapMskLen - EAX, bits 0..31
            if CAPMASKLEN_CPUID in line:
                regs = line.split(" ")
                CapMskLen = int(regs[5][6:14], 16)
                if (CapMskLen & 0xF):
                    self.log.info("PASS: Capacity Bit Mask Len Value = 0x%x" % CapMskLen)
                else:
                    self.log.info("CACEL: Capacity Bit Mask Len Not set")

            #CPUID EAX=0x00000010, ECX=0x00: L3Alloc - EBX bit 1
            if L3CACHE_ALLOC_CPUID in line:
                regs = line.split(" ")
                L3CacheAlloc = int(regs[6][6:14], 16)
                if (L3CacheAlloc & 0x2):
                    self.log.info("PASS: L3 Cache Allocation Enforcement Set")
                else:
                    self.log.info("CANCEL: L3 Cache Allocation Enforcement Unset")

            #CPUID EAX=0x80000008, ECX=0x00: BandWidthEnforce - eBX bit 6
            if BANDWIDTH_ENFORCE_CPUID in line:
                regs = line.split(" ")
                BandWidthEnforce = int(regs[6][6:14], 16)
                if (BandWidthEnforce & 0x40):
                    self.log.info("PASS: Bandwidth Enforcement Set")
                else:
                    self.log.info("CANCEL: Bandwidth Enforcement Unset")

    @staticmethod
    def init_MSR():
        """
        Initialize and test QOS related MSRs
        """
        global MSRDict, RWDict, ValueDict, MSRAddr
        MSRDict['0x0c81'] = 'L3QOSCFG1'
        MSRDict['0x0c90'] = 'AllocMask'
        MSRDict['0x0c8d'] = 'MEvtSel'
        MSRDict['0x0c8e'] = 'QOSL3Cnt'
        MSRDict['0x0200'] = 'BWCtrl'

        RWDict['0x0c81'] = 'RW'
        RWDict['0x0c90'] = 'RW'
        RWDict['0x0c8d'] = 'RW'
        RWDict['0x0c8e'] = 'R'
        RWDict['0x0200'] = 'RW'

        """
        Random values to test read/write permissions of MSRs
        """
        ValueDict['0x0c81'] = '1'
        ValueDict['0x0c90'] = '0xffff'
        ValueDict['0x0c8d'] = '0x99'
        ValueDict['0x0c8e'] = '0'
        ValueDict['0x0200'] = '0x05'

        MSRAddr = ['0x0c81','0x0c90','0x0c8d','0x0c8e','0x0200']

    def test_MSR(self):
        self.log.info(" -- Testing the MSRS for QOS --")
        self.init_MSR()
        global MSRAddr, MSRDict, RWDict, ValueDict
        ret = 0
        retsave = 0
        for m in MSRAddr:
            ret = 0
            out_readmsr = subprocess.Popen(['rdmsr', str(m)],
                    stdout=subprocess.PIPE, universal_newlines=True)
            readmsr = out_readmsr.stdout.read()
            if not "" == readmsr:
                self.log.info('%s is Accessible, value: %s', MSRDict[m],
                        readmsr)
                if RWDict[m] == 'RW':
                    value = ValueDict[m]
                    subprocess.Popen(['wrmsr', str(m), str(value)],
                            stdout=subprocess.PIPE, universal_newlines=True)
                    out1_readmsr = subprocess.Popen(['rdmsr', str(m)],
                            stdout=subprocess.PIPE, universal_newlines=True)
                    read_written_msr = out1_readmsr.stdout.read()
                    if not "" == read_written_msr:
                        self.log.info('PASS: %s: Able to write msr, Updated value: %s',
                                MSRDict[m], read_written_msr)
                else:
                    self.log.info('WARN: %s: Not writable, Retained value: %s',
                            MSRDict[m], readmsr)
            else:
                self.log.info('WARN: %s is not Accessible', MSRDict[m])

    def test_Kernel_Support(self):
        self.log.info(" -- Testing the kernel support for QOS --")
        """
        Function to test if the kernel supports PQOS/resource control
        """
        if os.path.exists("/sys/fs/resctrl"):
            self.log.info("PASS: Kernel Enabled with PQOS support, path /sys/fs/resctrl found.")
        else:
            self.fail("FAIL: Kernel doesn't support PQOS, check CONFIG_X86_CPU_RESCTRL enabled.")

if __name__ == '__main__':
	main()
