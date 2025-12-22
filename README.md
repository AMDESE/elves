### AMD EPYC Linux Validation Exerciser Suite
AMD EPYC Linux Validation Exerciser Suite (ELVES) is a Linux Kernel test suite for AMD EPYC servers
created and maintained by the AMD Linux test validation team.

The purpose is to host AMD EPYC feature-specific test cases that can run on the upstream Linux kernel. This
test repository will include AMD EPYC feature-specific tests, such as IOMMU, RAS, PQOS, Bus Lock Trap, and
virtualization-related test cases, as well as details on how each feature can be validated on AMD EPYC servers.

This repository contains a wrapper script and configuration files to allow the user to set up
Avocado Test Framework and run a suite of tests to help verify AMD EPYC Feature on baremetal and 
in a virtual machine environment.

### Supported Linux Distributions Version
Host Operating system - Ubuntu 24.04.3 LTS (Noble Numbat)<br>
Guest Operating system - Ubuntu 24.04.3 LTS (Noble Numbat)

### Supported component versions
The test cases published in this repository are validated with the following component versions:
- **Baremetal OS kernel**:
    * Minimum upstream kernel version: v6.14
    * Latest tested upstream version: v6.18
- **KVM guest kernel**:
    * upstream version: v6.18
- **QEMU**: v10.1.2
- **OVMF (EDK2)**: edk2-stable202511

### Supported Hardware
AMD EPYC 3rd Generation Processors Family 19h (codenamed "Milan")<br>
AMD EPYC 4th Generation Processors Family 19h (codenamed "Genoa")<br>
AMD EPYC 5th Generation processors Family 1Ah (codenamed "Turin")

### Steps to run the testcases
##### Note: Tests should be run with the superuser permissions.

1. Ensure that python3 and python3-pip packages are installed on the host operating system.
    ```bash
    apt install python3 python3-pip
    ```

2. If virtualization testcases need to be run, the guest disk image should be created by running create_guest_image.sh provided in this repository
    ```bash
    git clone https://github.com/AMDESE/elves.git
    cd elves
    bash create_guest_image.sh
    ```
    Note:
    1. Disk image creation is supported only for Ubuntu 24.04 LTS (Noble Numbat).
    2. When creating a guest image on a physical host with the SIT kernel module enabled, the appliance's IPv4 interface may fail to configure properly due to interference from the SIT0 interface. This issue is fixed in upstream libguestfs [commit](https://github.com/libguestfs/libguestfs/commit/dc218b25f0bc2704918748e4e8120ec436783e58).

3. Bootstrap the avocado environment:
    ```bash
    python3 ./avocado-setup.py --bootstrap --enable-kvm --install-deps --no-download
    ```
    Note: Remove --enable-kvm flag from above command if you are planning to run only baremetal testcases<br>

4. The AMD EPYC Feature specific test cases published for baremetal/host and virtualization:
    ```
    Baremetal testcases published under configuration file : elves/config/tests/host/AMD_elves.cfg
    Virtualization testcases published under configuration file : elves/config/tests/guest/qemu/AMD_elves.cfg
    ```

    Below are the locations of current Baremetal AMD EPYC Feature specific test cases hosted in [avocado-misc-tests](https://github.com/AMDESE/avocado-misc-tests/tree/AMD_elves):
    ```
    ras/amd/mce_mca
    qos/pqos/
        qos-llc-test.py
        sysfs-qos-mbm-test.py
    buslock/
    io/iommu/
        amd/
        interrupt.py
        sva.py
    memory/
        page_table.py
    cxl/cxl_test.py.data/
        driver-basic.py
        cxl-numa.py
        daxctl.py
        uefi.py
    cpu/
        rapl-core-energy.py
        rapl-pkg-energy.py
        hwmon-powercap.py
        pmqos-cpu-latency.py
        cpuidle-usage.py
        em_cpuidle.py
        amd_cpu_topology.py
    kernel/
        srso_mitigation.py
        tlbi_test.py
        kselftest.py used to run below AMD EPYC Feature specific test
            kvm: kvm_buslock_test
            cpufreq: basic, sptest1, sptest2
    ```
    There exists a readme file in each of above the test directories explaining the feature and the input requirements.

    Below are the current AMD EPYC virtualization Feature specific test cases hosted in [tp-qemu](https://github.com/AMDESE/tp-qemu/tree/AMD_elves)
    ```
    AMD CVM guest boot tests: qemu/tests/amd_cvm_boot.py
    AMD SNP guest attestation: qemu/tests/snp_attestation.py
    Idle HLT Intercept: qemu/tests/idlehlt.py
    EPYC-cpu model verification: qemu/tests/x86_cpu_model.py
    SNP host kernel parameter verification: qemu/tests/test_snp_params.py
    Kdump/kexec verification on AMD CVM: generic/tests/kdump.py
    Segmented RMP table validation: qemu/tests/segmented_rmp_validation.py
    Guest boot tests in different IOMMU modes: qemu/tests/qemu_pci_passthrough.py
    srso mitigation verification test using avocado-misc-test: generic/tests/avocado_guest.py
    ```

5. To run the testcases users should be updating the testcase specific inputs, guidance for which is provided in the respective test README files and test configuration files.
    Running the testcases:
    ```bash
    Running both baremetal and virtualization testcases:
    python3 ./avocado-setup.py --nrunner --vt qemu --run-suite host_AMD_elves,guest_AMD_elves --guest-os 24.04-server.x86_64 --no-download
    Running only baremetal testcases:
    python3 ./avocado-setup.py --nrunner --run-suite host_AMD_elves --no-download
    Running only virtualization testcases:
    python3 ./avocado-setup.py --nrunner --vt qemu --run-suite guest_AMD_elves --guest-os 24.04-server.x86_64 --no-download
    ```
The ELVES project is forked from [tests](https://github.com/lop-devops/tests). We intend to funnel relevant changes back to the parent project. If you encounter any issues related to the AMD platform-specific IP testcases listed above, we kindly ask that you open a GitHub issue in this repository. Please provide detailed information following the bug report template to help us address the problem efficiently.

For any issues related to the parent project or other projects mentioned in the references section, we encourage you to open an issue in the respective parent repository. Since all referenced projects are open-source, you are also welcome to contribute directly to them.

### Reference Kernel Configurations
The `reference_kconfig` folder contains sample host and guest kernel configuration files used to validate the test cases in this repository. 

### References:
[Avocado Test Framework](https://github.com/avocado-framework/avocado)<br>
[Avocado Test Framework documenation](https://avocado-framework.readthedocs.io/en/103.0/)<br>
[Avocado Tests repository](https://github.com/lop-devops/test)<br>
[Avocado-vt Plugin for KVM](https://github.com/avocado-framework/avocado-vt)<br>
KVM Tests: [Qemu Test repository](https://github.com/autotest/tp-qemu), [Libvirt Test repository](https://github.com/autotest/tp-libvirt)

### Known Issues and Limitation:

1. Recent Linux kernel versions (starting from v6.17.8) have been disabling RDSEED on AMD EPYC platforms based on Zen 5 architecture, citing AMD security bulletin AMD-SB-7055[](https://www.amd.com/en/resources/product-security/bulletin/amd-sb-7055.html). As a result, the CPU model verification test cases are cancelled on whenever RDSEED is listed as an unavailable feature. This is a known limitation that is currently under investigation to determine whether the fix should be applied in the test case or in QEMU.

2. Recent firmware versions on AMD EPYC platforms include security patches that prevent SEV-ES guest types from booting when SNP support is enabled. A workaround for booting SEV-ES guests is to either disable SEV-SNP in the BIOS or boot the kernel with the `sev=nosnp` command-line parameter.

Also refer to [Issues](https://github.com/AMDESE/elves/issues) in this repository for details on bugs, limitations, future enhancements, and investigations.

Click [here](https://github.com/AMDESE/elves/issues/new/choose) to open a new issue.
