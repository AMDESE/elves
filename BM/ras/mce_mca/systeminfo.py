#!/usr/bin/env python
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2025 Advanced Micro Devices, Inc.
# @Author:   Smita Koralahalli Channabasappa <Smita.KoralahalliChannabasappa@amd.com>
# @Module Name: systeminfo.py
# @Description: Covers common helper functions.
# @History:  Created Jan 10 2025 - Created

import os
import logging
import subprocess
from subprocess import call, Popen, PIPE
from avocado.utils import linux_modules

def Run(cmd):
    """
    Run a cmd[], return the exit code, stdout, and stderr.
    """
    proc=subprocess.Popen(cmd, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, shell=True, universal_newlines=True)
    out, err = proc.communicate()
    return proc.returncode, out, err

def check_module_load(mod, mod_config):
    """
    Check for module config and load if not loaded
    """
    ret = 0
    config_check = linux_modules.check_kernel_config(mod_config)
    if config_check == linux_modules.ModuleConfig.NOT_SET:
        ret = -1
        logging.info('Config %s is not set', mod_config)
    else:
        if linux_modules.load_module('msr'):
            logging.info('Module Load Success')
        else:
            ret = 1
            logging.info('Module Load Failed')

    return ret

def get_current_equivalent_id():
    """
    Returns the current equivalent_id in reg eax at function 0x80000001 in
    cpuid
    """
    cpuid_info = Popen(["cpuid", "-1", "-r"], stdout=PIPE,
            universal_newlines=True)
    cpuid = Popen(["grep", "0x80000001"], stdin=cpuid_info.stdout,
            stdout=PIPE, universal_newlines=True).communicate()[0]
    cpuid_info.stdout.close()
    cpu_id = cpuid.split(" ")
    eq_id = cpu_id[5][4:14]
    return eq_id

def get_cpu_info():
    """
    Returns Number of thread(s) per core, number of core(s) per socket
    and number of socket(s)
    """
    lscpu_info = Popen(["lscpu"], stdout=PIPE, universal_newlines=True)
    cpu_info = Popen(["grep", "-E", "'|^Thread|^Core|^Socket'"],
            stdin=lscpu_info.stdout, stdout=PIPE,
            universal_newlines=True).communicate()[0]
    lscpu_info.stdout.close()
    cpu_info = cpu_info.strip('\n').split('\n')
    return cpu_info

if __name__ ==  "__main__":
    main()
