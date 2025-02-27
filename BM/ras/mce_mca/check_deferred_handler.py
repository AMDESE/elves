#!/usr/bin/env python
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2025 Advanced Micro Devices, Inc.
# @Author:   Smita Koralahalli Channabasappa <Smita.KoralahalliChannabasappa@amd.com>
# @Module Name: check_deferred_handler
# @Description: Check if deferred error interrupt handler is installed
# @History:  Created Jan 10 2025 - Created

from avocado import Test
import subprocess
from subprocess import Popen, PIPE
import os, re
import systeminfo
from systeminfo import Run

class MceTest(Test):
    def test_deferred_err_inthandler_installed(self):
        """
        Check for dmesg and vector value read from APIC520
        """
        # Check in dmesg for APIC LVT 520
        dmesg_info = Popen(["dmesg"], stdout=PIPE, universal_newlines=True)
        dmesg_log = Popen(["grep", "LVT"], stdin=dmesg_info.stdout, stdout=PIPE,
                universal_newlines=True).communicate()[0]
        dmesg_info.stdout.close()

        # Try journalctl if dmesg log is tructed or cleared
        jrl_info = Popen(["journalctl"], stdout=PIPE, universal_newlines=True)
        jrl_log = Popen(["grep", "LVT"], stdin=jrl_info.stdout, stdout=PIPE,
                universal_newlines=True).communicate()[0]
        jrl_info.stdout.close()

        if (("LVT offset 2 assigned for vector 0xf4" in dmesg_log) or
            ("LVT offset 2 assigned for vector 0xf4" in jrl_log)):
            self.log.info("PASS: Deferred error interrupt handler is installed")

            # Check for msr module load
            ret = systeminfo.check_module_load('msr', 'CONFIG_X86_MSR')
            if (ret < 0):
                self.fail("Config CONFIG_X86_MSR is not set")
            elif (ret > 0):
                self.fail("MSR module load failed on the system")
            else:
                self.log.info("MSR Module Load Success")

            # Number of CPUs > 256, build/install upstream msr-tools
            code, num_cpus, err = systeminfo.Run(["nproc"])
            if (int(num_cpus) > 256):
                code, out_APIC520, err = systeminfo.Run(["rdmsr -p 256 0x0852"])
                if (out_APIC520 == ''):
                    self.cancel("System having more than 255 CPUs, install upstream msr-tools")

            # Check for appropriate vector value for APIC 520 across all CPUs
            for cpu in range(0, int(num_cpus)):
                code, out_APIC520, err = systeminfo.Run(["rdmsr -p %s 0x0852" % (cpu)])

                if (out_APIC520 != ''):
                    if int(out_APIC520, 16) != 0xf4:
                        self.fail("APIC 520 is not written with appropriate vector value for cpu %d",
                            cpu)
                    else:
                        self.log.info("PASS: APIC 520 has been written with appropriate vector value for cpu %d",
                            cpu)
                else:
                    self.fail("Unsupported APIC 520")
        else:
            self.fail("Deferred error interrupt handler is not installed")

if __name__ == "__main__":
    main()
