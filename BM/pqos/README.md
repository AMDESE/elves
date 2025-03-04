# AMD Quality Of Server(QOS) or Platform Quality Of Service(PQOS)
AMD Quality of Service(PQoS or just QoS) is intended to provide the interface for the monitoring of the usage of
certain system resources by one or more processors and also provide the interface for allocation of limits on the
use of certain system resources. These technologies enable tracking and control of shared resources, such as the
Last Level Cache (LLC) and main memory (DRAM) bandwidth, in use by many applications, containers or VMs running on
the platform concurrently.

Quality of Service (QOS) features defined and implemented by the Cache Hierarchy to support the AMD64 Platform
Quality of Service Features. The QOS features provide mechanisms for the user to monitor shared resource utilization and,
separately, enforce limits on those shared resources. These QOS features operate in a QOS Domain of the Core Complex (CCX).
The shared resources monitored and controlled are L3 Cache Occupancy and L3 System Memory Bandwidth. The capabilities of
feature set are enumerated through CPUID identifiers so that software can easily support multiple instances of the feature.
The CPUID identifiers indicate the presence of MSR’s used to interact with the QOS features.

Links:
https://www.kernel.org/doc/Documentation/x86/resctrl.rst
https://www.amd.com/content/dam/amd/en/documents/processor-tech-docs/programmer-references/40332.pdf

# Linux QoS Interfaces
QoS functionality can be achieved by following interfaces:
a. CPUID check for feature support
b. MSR interface
c. Sysfs interface
d. Intel CMT(Cache Monitoring Technology) and CAT(Cache Allocation Technology) interface i.e pqos tool/utility developed by Intel
	Reference: https://eci.intel.com/docs/3.0.1/development/intel-pqos.html
	# How To Install PQoS tool
		# On Ubuntu - $ sudo apt install intel-cmt-cat
		# After install run with command - $ pqos

# Pre-requisites
a. Install pqos tool i.e 'intel-cmt-cat' (See - How To Install PQoS tool above)
b. Install msr-tools. For example on Ubuntu - apt-get install msr-tools
c. Ensure the booted kernel is built with config - "CONFIG_X86_CPU_RESCTRL=y".

# QoS feature testing coverage
a. Memory bandwidth monitoring
b. Memory bandwidth control
c. L3 cache occupancy monitoring
d. L3 cache allocation control

# PQOS tests
Avocado framework is used to run "pqos" tests. Setup avocado and install pqos tool, cpuid, msr-tools for tests to run successfully.
The following tests are covered as part of PQOS.
1. qos.py: CPUID feature check and MSR check tests
2. qos-llc-test.py: Detect L3 Cache Alloaction and check if able to set up allocation COS and test reset COS
3. qos-mbm-test.py: Checks for Memory Bandwidth Allocation detection and control feature
4. sysfs-qos-llc-test.py: Check resource control support(Resctrl), mount, allocate half cache and validate the feature
5. sysfs-qos-mbm-test.py: Checks for resctrl support and detect for L3 resctrl

# How to run the tests
cd BM/pqos
avocado run --max-parallel-tasks=1 qos.py
avocado run --max-parallel-tasks=1 qos-llc-test.py
avocado run --max-parallel-tasks=1 qos-mbm-test.py
avocado run --max-parallel-tasks=1 sysfs-qos-llc-test.py
avocado run --max-parallel-tasks=1 sysfs-qos-mbm-test.py

# Observations
a. Used "--max-parallel-tasks=1" avocado option to run tests sequentially. It has been observed in case of sysfs-qos-llc-test.py test runs,
   resctrl_allocate test failed when retest test runs first.
b. If the test depends on the boot time dmesg, for example, in case of test_pqos_resctrl_detection, it grep for "LVT" in the dmesg. If for some reason
   dmesg is cleared or truncted the test may fail. To confirm the test passes the user can run the test when boot time dmesg is not cleared or truncated.
#EOF
