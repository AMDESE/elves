#!/usr/bin/env python
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2025 Advanced Micro Devices, Inc.
# @Author:   Smita Koralahalli Channabasappa <Smita.KoralahalliChannabasappa@amd.com>
# @Module Name: check_threshold_handler.py
# @Description: Check if thresholding interrupt handler is installed
# @History:  Created Jan 10 2025 - Created

from avocado import Test
import subprocess
from subprocess import Popen, PIPE
import os, re
import systeminfo
from systeminfo import Run

class MceTest(Test):
    def test_MCA_thresholding_inthandler_installed(self):

        # Check for msr module load
        ret = systeminfo.check_module_load('msr', 'CONFIG_X86_MSR')
        if (ret < 0):
            self.fail("Config CONFIG_X86_MSR is not set")
        elif (ret > 0):
            self.fail("MSR module load failed on the system")
        else:
            self.log.info("MSR Module Load Success")

        # Check if MCA Thresholding is set
        # A valid threshold counter present and not locked
        code, out_MCA_MISC, err = systeminfo.Run(["rdmsr 0xc0002003"])
        if ((int(out_MCA_MISC, 16) >> 61) & 7 != 6):
            self.cancel("System configuration does not support MCA Thresholding")

        # Check in dmesg for APIC LVT 510
        dmesg_info = Popen(["dmesg"], stdout=PIPE, universal_newlines=True)
        dmesg_log = Popen(["grep", "LVT"], stdin=dmesg_info.stdout, stdout=PIPE,
                universal_newlines=True).communicate()[0]
        dmesg_info.stdout.close()

        # Try journalctl if dmesg log is tructed or cleared
        jrl_info = Popen(["journalctl"], stdout=PIPE, universal_newlines=True)
        jrl_log = Popen(["grep", "LVT"], stdin=jrl_info.stdout, stdout=PIPE,
                universal_newlines=True).communicate()[0]
        jrl_info.stdout.close()

        if (("LVT offset 1 assigned for vector 0xf9" in dmesg_log) or
            ("LVT offset 1 assigned for vector 0xf9" in jrl_log)):
            self.log.info("PASS: MCA Thresholding interrupt handler is installed")

            # Number of CPUs > 256, build/install upstream msr-tools
            code, num_cpus, err = systeminfo.Run(["nproc"])
            if (int(num_cpus) > 256):
                code, out_APIC510, err = systeminfo.Run(["rdmsr -p 256 0x0851"])
                if (out_APIC510 == ''):
                    self.cancel("System having more than 255 CPUs, install upstream msr-tools")

            # Check for appropriate vector value for APIC 510 across all CPUs
            for cpu in range(0, int(num_cpus)):
                code, out_APIC510, err = systeminfo.Run(["rdmsr -p %s 0x0851" % (cpu)])

                if (out_APIC510 != ''):
                    if int(out_APIC510, 16) != 0xf9:
                        self.fail("APIC 510 is not written with appropriate vector value")
                    else:
                        self.log.info("PASS: APIC 510 has been written with appropriate vector value for cpu %d",
                            cpu)
                else:
                        self.fail("Unsupported APIC 510")
        else:
            self.fail("MCA Thresholding interrupt handler is not installed")

if __name__ == "__main__":
    main()
