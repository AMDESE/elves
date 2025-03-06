### AMD EPYC Linux Validation Exerciser Suite
AMD EPYC Linux Validation Exerciser Suite (ELVES) is a Linux Kernel test suite runs on AMD EPYC
servers. It is a work in progress test project created and maintained by AMD Linux test validation
team.

The purpose is to host AMD EPYC IP specific test cases that can run on upstream Linux kernel. This
test repository will include AMD EPYC IP specific feature tests like IOMMU, RAS, PQOS. In addition,
it adds details on how each of the features can be used or validated on AMD EPYC servers.

[BM (Bare Metal)](BM/README.md) involves testing on AMD servers without any hypervisor or
virtualization software.

### Note:
Tests should be run with the supervisor permission (ex: root user).

### More details please refer to the following BM features:

**<span class="underline">BM Features</span>**

-   [IOMMU](BM/iommu/README.md)

-   [PQOS](BM/pqos/README.md)

-   [RAS](BM/ras/README.md)

### Tested Linux Distributions Version
- Ubuntu 24.04.2 LTS (Noble Numbat)

### Tested Hardware
- Genoa(1P) - AMD EPYC 9654 96-Core Processor
- Turin(2P) - AMD EPYC 9555 64-Core Processor

### Tested Kernel
- Upstream stable kernel - version string: v6.14

### Avocado LTS Version
- Avocado 103.0

### Disclaimer:
This project is in its early development stages, and as such, its structure, features, and functionality may subject to change in future releases. We appreciate your patience and understanding as we continue to refine and improve the project.
