# **<span class="underline">IOMMU</span>** 

I/O Memory Management Unit (IOMMU) extends AMD platform to support DMA remapping.
DMA remapping feature provides system memory access protection for DMA transfer from
peripheral devices. IOMMU also helps filter and remap interrupt from peripheral
devices. In addition, IOMMU does support other features like SVA, ATS etc.
For more details, please refer to the IOMMU specification below.

- https://www.amd.com/content/dam/amd/en/documents/processor-tech-docs/specifications/48882_IOMMU.pdf

## **<span class="underline">Some kernel command line options available for IOMMU</span>**

-   **iommu=off**

    **Description:** IOMMU is disabled. DMA transfers and interrupt delivery from
    peripheral devices can be tested to check system behavior without IOMMU.

    **Validation:** If IOMMU is disabled then dmesg doesn't contain "AMD-Vi".
```
   dmesg | grep -i "AMD-Vi"
```

<!-- -->

-   **iommu=nopt**

    **Description:** System boots with IOMMU DMA remapping feature enabled. IOMMU setup
    and maintain page table for GPA -> SPA translation for all DMA transfers from
    peripheral devices. Tests can exercise IOMMU page table walk for GPA -> SPA
    translation for valid DMA transfer from peripheral. Tests can also exercise map
    and unmap paths for IOMMU page table.

    **Validation:** If IOMMU is in DMA remapping mode then dmesg contains "iommu: Default domain
                type: Translated".
```
   dmesg | grep -i -e "iommu"
```

<!-- -->

-   **iommu=pt**

    **Description:** IOMMU DMA remapping feature is disabled. In this mode, all DMA transfer
    from peripheral device will be intercepted by IOMMU for permission check without being
    remapped (GPA = SPA).

    **Validation:** If IOMMU is in pass-through mode then dmesg contains "iommu: Default domain
                type: Passthrough".
```
   dmesg | grep -i -e "iommu"
```
<!-- -->

-   **amd\_iommu=pgtbl\_v1**

    **Description:** In this mode (if DMA remapping is enabled), IOMMU uses v1 (host) page
    table for GPA -> SPA translation. In this mode, IOMMU test cases can exercises if
    IOMMU can initialize v1 page table for peripherals, map-unmap page table entries and
    do GPA -> SPA translation for valid DMAs.

    **Validation:** If system is booted with IOMMU v1 page table mode then dmesg doesn't
                contains "AMD-Vi: V2 page table enabled".
```
   dmesg | grep -i "AMD-Vi"
```

<!-- -->

-   **amd\_iommu=pgtbl\_v2**

    **Description:** AMD IOMMU does support v2 (Guest) page table. Similar to IOMMU v1 page
    table, (if DMA remapping is enabled) IOMMU uses v2 page table for GPA --> SPA
    translation for DMA transfers from peripheral devices. IOMMU test cases can exercises
    if IOMMU can initialize v2 page table for peripherals, map-unmap page table entries
    and do GPA -> SPA translation for valid DMAs.

    **Validation:** If system is booted with IOMMU v2 page table mode then dmesg contains
                "AMD-Vi: V2 page table enabled".
```
   dmesg | grep -i "AMD-Vi"
```

<!-- -->

-   **intremap=on**

    **Description:** IOMMU intercept, filter and remap all the interrupts from peripheral
    devices.

    **Validation:** If IOMMU interrupt remapping feature is enabled then dmesg contains
                "AMD-Vi: Interrupt remapping enabled".
```
   dmesg | grep -i "AMD-Vi"
```

<!-- -->

-   **intremap=off**

    **Description:** IOMMU interrupt remapping feature is disabled. Tests can check if
    interrupt delivery from peripheral devices should work fine without being intercepted
    by IOMMU.

    **Note:** With interrupt remapping feature disabled, kernel supports upto 255 apic ids.

    **Validation:** If IOMMU interrupt remapping feature is disabled then dmesg doesn't contain
                "AMD-Vi: Interrupt remapping enabled".
```
   dmesg | grep -i "AMD-Vi"
```

## **<span class="underline"> IOMMU should be tested for different boot mode combination. Some are listed below </span>**

-   iommu=off

<!-- -->

-   iommu=nopt intremap=on amd\_iommu=pgtbl\_v1 

<!-- -->

-   iommu=nopt intremap=on amd\_iommu=pgtbl\_v2 

<!-- -->

-   iommu=nopt intremap=off amd\_iommu=pgtbl\_v1 

<!-- -->

-   iommu=nopt intremap=off amd\_iommu=pgtbl\_v2

<!-- -->

-   iommu=pt intremap=on


Boot the system with different IOMMU boot mode combinations and run below tests.

**Note:** Each kernel command line options of IOMMU boot mode combination must be
validated from dmesg before testing. eg. for system booted with "iommu=nopt intremap=on
amd\_iommu=pgtbl\_v1", dmesg should be validated for "iommu=nopt", "intremap=on" and
"amd\_iommu=pgtbl\_v1" before testing.

# **<span class="underline">IOMMU TEST CASES:</span>** 

## **Change IOMMU domain type test** 

**Description :** Linux supports changing IOMMU domain type at run time of any pci device.
Changing IOMMU domain type for a pci device defines the "DMA remapping" behavior of
IOMMU for that pci device.

- DMA: All the DMA transactions from the device in this group are translated by IOMMU.
- DMA-FQ: As above, but use flush queue for batched IOMMU tlb invalidations.
- identity: All the DMA transactions from the device in this group are not translated by the IOMMU.
- auto: Change to the type the device was booted with.

**Note :** The default domain type of a group may be modified only when the device in
the group is not bound to any device driver.
**Note:** This test is valid only for IOMMU DMA remapping mode, else it will be canceled.

**Running the test :**
```
avocado run avocado-misc-tests/io/iommu/iommu_tests.py -p pci_devices="{full_pci_address}" -p dmesg_grep="iommu|AMD-Vi" -p count=4 --max-parallel-tasks=1
```

**Note :** Running this test needs at least one pci device input 'pci\_devices'. eg.
```
avocado run avocado-misc-tests/io/iommu/iommu_tests.py -p pci_devices="0000:01:00.0" -p dmesg_grep="iommu|AMD-Vi" -p count=4 --max-parallel-tasks=1
```

**Note :** Test fails if it introduces IOMMU related warning, alert, critical and error logs
in the dmesg. Warning, alert, critical and error logs from other drivers are ignored.
  

## **IOMMU v2 page table level validation test** 

**Description :** Maximum supported level for CPU page table should match with IOMMU page
table level in v2 mode.

**Note :** This test is valid only for IOMMU v2 page table mode, else it will be canceled.

**Running the test :**
```
avocado run avocado-misc-tests/io/iommu/amd/iommu_v2pgmode_test.py 
```
