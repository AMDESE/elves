#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2025 AMD Corporation
# Author(s): Kalpana Shetty <Kalpana.Shetty@amd.com>
#            Babu Moger <Babu.Moger@amd.com>
# @Module Name: qos_resctrllib.py
# @Description: Common functions used i resource control testing
# @History:  Created Jan 10 2025 - Created

import os
import logging
import platform
from lib.qos_common import *

RESCTRL_PATH = "/sys/fs/resctrl"

class ResctrlSchemata:
    def is_mounted(self):
        command = "mount -t resctrl"
        _, output, _ = CommonLib.Run(command)
        logging.info(output)
        logging.info("=" * 30)
        return "resctrl" in output and "rw" in output

    def mount(self):
        if not os.path.ismount(RESCTRL_PATH):
            command = "sudo mount -t resctrl resctrl %s" % (RESCTRL_PATH)
            exitstatus, output, _ = CommonLib.Run(command)
            return self.is_mounted()
        else:
            command = "sudo mount |grep %s" % (RESCTRL_PATH)
            exitstatus, output, _ = CommonLib.Run(command)
            logging.info(output)
        logging.info("=" * 30)

    def umount(self):
        command = "sudo umount -a -t resctrl"
        exitstatus, stdout, _ = CommonLib.Run(command)
        assert exitstatus == 0
        command1 = "sudo mount |grep %s" % (RESCTRL_PATH)
        _, stdout, _ = CommonLib.Run(command1)
        logging.info(stdout)
        return not self.is_mounted()

    def resctrl_detection(self):
        logging.info("Starting QoS LLC tests using sysfs")
        config_file = "config-{0}".format(platform.release())
        boot_file = os.path.join("/boot/", config_file)
        module_file = os.path.join("/lib/modules/", config_file)
        if os.path.exists(boot_file):
            (exitstatus, stdout, _) = CommonLib.Run(["cat /boot/config-`uname -r`| grep -i resctrl"])
            logging.info(stdout)
            assert exitstatus == 0
            assert "CONFIG_X86_CPU_RESCTRL" in stdout
        else:
            if os.path.exists(module_file):
                (exitstatus, stdout, _) = CommonLib.Run(["cat /lib/modules/config-`uname -r`/boot/.config| grep -i resctrl"])
                logging.info(stdout)
                assert exitstatus == 0
                assert "CONFIG_X86_CPU_RESCTRL" in stdout

        logging.info("Checking L3 resctrl in dmesg")
        (exitstatus, stdout, _) = CommonLib.Run(["dmesg |grep 'resctrl: L3 allocation detected'"])
        if (exitstatus != 0):
            logging.info("Checking L3 resctl in journalctl")
            (exitstatus, stdout, _) = CommonLib.Run(["journalctl |grep 'resctrl: L3 allocation detected'"])
            assert exitstatus == 0
        assert "resctrl: L3 allocation detected" in stdout
