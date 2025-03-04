#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2025 AMD Corporation
# @Author(s): Kalpana Shetty <Kalpana.Shetty@amd.com>
#             Babu Moger <Babu.Moger@amd.com>
# @Module Name: qos_common.py
# @Description: Includes common functions used in pqos tests
# @History:  Created Jan 10 2025 - Created

import sys
import subprocess
import os.path
import logging
from avocado.utils import distro
from avocado.utils.software_manager.manager import SoftwareManager

class CommonLib:
    @classmethod
    def Run(self, cmd):
        """
        Run a cmd[], return the exit code, stdout, and stderr.
        """
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE, shell=True, universal_newlines=True)
        stdout, stderr = proc.communicate()

        return proc.returncode, stdout, stderr
