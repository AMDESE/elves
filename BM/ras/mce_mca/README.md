# Pre-requisites
        - Install msr-tools
                $ apt-get install msr-tools    ## Use respective distro package install command

# Known Issues
 The Linux distribution(Ubuntu 24.04 or RHEL-9.5) installed msr-tools i.e readmsr command only supports upto 256 CPUs
 If your system having more than 256 CPUs, please git clone upstream msr-tool, build and install to get all fixes/changes.
	Upstream msr-tools: https://github.com/intel/msr-tools

# Test case information
These are MCE/MCA test cases. Please run using "avocado run <test_name>"

1. Module Name - check_deferred_handler
   Description: Check if deferred error interrupt handler is installed
   How to run:
	# cd BM/ras/mce_mca
        # avocado run check_deferred_handler.py

2. Module Name: check_mca_config
   Description: This module tests if MCA_CONFIG[McaXEnable] = 1 and
       MCA_CONFIG[DeferredIntType] = 01b whereas other fields
       are at "Reset" or "Init: BIOS" values, across all banks
       for each logical CPU.
   How to run:
	# cd BM/ras/mce_mca
        # avocado run check_mca_config.py

3. Module Name = check_threshold_handler.py
   Description: Check if thresholding interrupt handler is installed
   How to run:
	# cd BM/ras/mce_mca
        # avocado run check_threshold_handler.py

4. Module Name = mce_sysfs_init
   Description: Check for mce sysfs device initialization
   How to run:
	# cd BM/ras/mce_mca
        # avocado run mce_sysfs_init.py
# EOF
