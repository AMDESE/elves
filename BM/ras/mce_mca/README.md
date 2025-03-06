# Pre-requisites
- Install the msr-tools package by using your distribution's package manager. On Ubuntu systems
```
   apt-get install msr-tools
```

# Note(s)
1. Tests like check_deferred_handler.py, look for "LVT" in the boot time dmesg log. If the boot time dmesg is cleared or has truncted log may
   cause failure in this test case, hence now a check has been added to look for "LVT" in 'journalctl' log in addition to dmesg log.

2. ras tests should be run with supervisor permission(ex: the root user).

# Test case information
These are MCE/MCA test cases. Please run using "avocado run <test_name>"

1. **Module Name** - check_deferred_handler

   **Description:** Check if deferred error interrupt handler is installed

   **How to run:**
```
   cd BM/ras/mce_mca
   avocado run check_deferred_handler.py
```

2. **Module Name:** check_mca_config

   **Description:** This module tests if MCA_CONFIG[McaXEnable] = 1 and
   MCA_CONFIG[DeferredIntType] = 01b whereas other fields are at "Reset"
   or "Init: BIOS" values, across all banks for each logical CPU.

   **How to run:**
```
   avocado run check_mca_config.py
```

3. **Module Name** = check_threshold_handler.py

   **Description:** Check if thresholding interrupt handler is installed

   **How to run:**
```
   avocado run check_threshold_handler.py
```

4. **Module Name** = mce_sysfs_init

   **Description:** Check for mce sysfs device initialization

   **How to run:**
```
   avocado run mce_sysfs_init.py
```

# Known Issues
  msr-tools issue with more than 256 CPUs
  ras/mce_mca tests will fail if it runs on a system with more than 256 CPUs. The issue is with 'msr-tools' installed from linux distribution.
  The issue is fixed in upstream 'msr-tools'. It is recommended to install upstream 'msr-tools' tool to get ras/mce_mca tests runs successfully.

- Upstream msr-tools: https://github.com/intel/msr-tools.git

- Steps to build and install upstream 'msr-tools' on Ubuntu systems:
```
   # Pre-requisites packages to be installed
   apt-get -qq --yes install libtool
   git clone https://github.com/intel/msr-tools.git
   cd msr-tools
   ./autogen.sh
   make install
```
