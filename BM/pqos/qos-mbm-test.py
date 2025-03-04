#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2025 Advanced Micro Devices, Inc.
# @Author(s): Kalpana Shetty <Kalpana.Shetty@amd.com>
#             Babu Moger <Babu.Moger@amd.com>
# @Module Name: qos-mbm-test.py
# @Description: Checks for Memory Bandwidth Allocation detected
# @History:  Created Jan 10 2025 - Created

import re
import subprocess
import time
import math
import os.path
import avocado
from avocado import Test
from lib.qos_common import *

class Pqos(Test):
    ## PQOS - MBA Detection
    #
    #  Objective:
    #  Verify MBA capability is detected on platform
    #
    #  Instruction:
    #  Run "pqos -I -s -v" to print capabilities and configuration in verbose
    #  mode
    #
    #  Result:
    #  Observe "MBA capability detected" in output
    @avocado.skipIf(not(os.path.exists("/sys/fs/resctrl")), 'Skipping test,no support for QOS')
    def test_pqos_mbm_detection(self):
        self.log.info("Starting QoS MBM tests using PQOS command line utility")
        self.log.info("Executing pqos -s -v to detect MBM capability")
        os.environ['LD_LIBRARY_PATH'] = '/usr/local/lib'
        (exitstatus, stdout, _) = CommonLib.Run(["pqos -I -s -v"])
        assert exitstatus == 0
        self.log.info(stdout)
        assert "MBA capability detected" in stdout
