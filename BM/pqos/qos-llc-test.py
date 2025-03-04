#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2025 Advanced Micro Devices, Inc.
# @Author(s): Kalpana Shetty <Kalpana.Shetty@amd.com>
#             Babu Moger <Babu.Moger@amd.com>
# @Module Name: qos-llc-test.py
# @Description: Detect L3 Cache Alloaction and check if able to set up allocation COS and test reset COS
# @History:  Created Jan 10 2025 - Created

import re
import subprocess
import time
import math
import os.path
import avocado
from avocado import Test
from lib.qos_common import *
from lib.qos_resctrllib import ResctrlSchemata

class Pqos(Test):
    ## PQOS - L3 CAT Detection
    #
    #  Objective:
    #  Verify L3 CAT capability is detected on platform
    #
    #  Instruction:
    #  CommonLib.Run "pqos -I -s -v" to print capabilities and configuration in verbose
    #  mode
    #
    #  Result:
    #  Observe "L3CA capability detected" in output
    @avocado.skipIf(not(os.path.exists("/sys/fs/resctrl")), 'Skipping test, No support for QOS')
    def test_pqos_l3cat_detection(self):
        self.log.info("Starting QoS LLC tests using PQOS command line utility")
        self.log.info("Executing pqos -s -v to detect LLC capability")
        ResctrlSchemata().umount()
        os.environ['LD_LIBRARY_PATH'] = '/usr/local/lib'
        (exitstatus, stdout, _) = CommonLib.Run(["pqos -I -s -v"])
        assert exitstatus == 0
        self.log.info(stdout)
        assert "L3CA capability detected" in stdout

    ## PQOS - L3 CAT Set COS definition
    #
    #  Objective:
    #  Able to set up allocation COS
    #
    #  Instruction:
    #  1. CommonLib.Run the "pqos -e 'llc:0=0xff;" to set COS bitmask.
    #  2. Verify values with "pqos -s"
    #
    #  Result:
    #  1. Observe in output
    #     L3CA COS0 => MASK 0xff
    #     Allocation configuration altered.
    #  2. L3CA COS0 MASK for socket 0 is set to 0xff
    @avocado.skipIf(not(os.path.exists("/sys/fs/resctrl")), 'Skipping test, No support for QOS')
    def test_pqos_l3cat_setup(self):
        self.log.info("Run the pqos -e llc:0=0xff to set COS bitmask")
        os.environ['LD_LIBRARY_PATH'] = '/usr/local/lib'
        (exitstatus, stdout, _) = CommonLib.Run(["pqos -e llc:0=0xff;"])
        assert exitstatus == 0
        assert "L3CA COS0 => MASK 0xff" in stdout
        self.log.info(stdout)
        assert "Allocation configuration altered" in stdout

        (exitstatus, stdout, _) = CommonLib.Run(["pqos -s"])
        assert exitstatus == 0
        assert "L3CA COS0 => MASK 0xff" in stdout

    ## PQOS - L3 CAT reset
    #
    #  Objective:
    #  Reset CAT allocation
    #
    #  Instruction:
    #  1. Reset the allocation and verify
    #
    #  Result:
    #  Observe in output file
    #    - Allocation reset successful
    def test_pqos_l3cat_reset(self):
        self.log.info("Reset the PQOS. Execute pqos -R")
        os.environ['LD_LIBRARY_PATH'] = '/usr/local/lib'
        (exitstatus, stdout, _) = CommonLib.Run(["pqos -R"])
        assert exitstatus == 0
        assert "Allocation reset successful" in stdout
        self.log.info(stdout)
