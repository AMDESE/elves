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
Host Operating system - Ubuntu 24.04.2 LTS (Noble Numbat)<br>
Guest Operating system - Ubuntu 24.04.2 LTS (Noble Numbat)

### Supported Hardware
AMD EPYC processors Family 19h (codenamed "Genoa")<br>
AMD EPYC processors Family 1Ah (codenamed "Turin")

### Supported Kernel
The testcases published are tested against Linux upstream kernel.<br>
Minimum upstream kernel version: v6.14<br>
Latest tested upstream version: v6.14.5

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
    Note: Disk image creation is supported only for Ubuntu 24.04 LTS (Noble Numbat).<br>

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
    buslock/
    io/iommu/
    io/iommu/amd/
    ```
    There exists a readme file in each of above the test directories explaining the feature and the input requirements.

    Below are the current AMD EPYC virtualization Feature specific test cases hosted in [tp-qemu](https://github.com/AMDESE/tp-qemu)
    ```
    AMD SEV-SNP guest boot test: qemu/tests/snp_boot.py
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
The ELVES project is forked off of [tests](https://github.com/lop-devops/tests). We intend to funnel back changes to the parent project as relevant.

### References:
[Avocado Test Framework](https://github.com/avocado-framework/avocado)<br>
[Avocado Test Framework documenation](https://avocado-framework.readthedocs.io/en/103.0/)<br>
[Avocado Tests repository](https://github.com/lop-devops/test)<br>
[Avocado-vt Plugin for KVM](https://github.com/avocado-framework/avocado-vt)<br>
KVM Tests: [Qemu Test repository](https://github.com/autotest/tp-qemu), [Libvirt Test repository](https://github.com/autotest/tp-libvirt)

### Known Issues and Limitation:
Refer to [Issues](https://github.com/AMDESE/elves/issues) in this repository for details on bugs, limitations, future enhancements, and investigations.

Click [here](https://github.com/AMDESE/elves/issues/new/choose) to open a new issue.
