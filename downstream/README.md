### ELVES downstream distributions

Downstream host OS support is documented here. The upstream Ubuntu
host/guest and virtualization flow is unchanged in the [top-level
README](../README.md) (guest distro, KVM/QEMU/OVMF versions, guest testcase list, and KVM references remain there).

Use the **`downstream`** branch for flows in this file.

### Supported downstream host operating systems

| Host OS | Scope | Host config file | Avocado run suite |
|---------|--------|------------------|-------------------|
| VeLinux-2.2 | Host (baremetal) only | `config/tests/host/VeLinux_elves.cfg` | `host_VeLinux_elves` |

The config path `VeLinux_elves.cfg` is used with run suite
`host_VeLinux_elves` (same pattern as `AMD_elves.cfg` with `host_AMD_elves`).

### Downstream validated component versions

The testcase sets in distro-specific config files are validated against the component levels below.
Structure matches the upstream **Supported component versions** section in the top-level README.

#### VeLinux-2.2

Validated against `config/tests/host/VeLinux_elves.cfg` / `--run-suite host_VeLinux_elves`:

- **Baremetal OS kernel**: v6.6 (VeLinux-2.2)
- **KVM guest kernel**: N/A (host (baremetal) only for now)
- **QEMU**: N/A
- **OVMF (EDK2)**: N/A

Update the kernel lines after each validation cycle on VeLinux-2.2.

### Steps to run the testcases on VeLinux-2.2

##### Note: Tests should be run with superuser permissions.

#### Prerequisites

1. Host running **VeLinux-2.2** on supported AMD EPYC hardware (see main README **Supported Hardware**).
2. Repository on branch **`downstream`**.
3. **python3** and **python3-pip** installed on the host.
4. VeLinux packages in **`config/wrapper/env.conf`**. Section name must match `ID` + `VERSION` from
   `/etc/os-release` (for example `[deps_debian]` when `ID=debian` and `VERSION_ID=13`).

#### 1. Clone the repository

```bash
git clone -b downstream https://github.com/AMDESE/elves.git
cd elves
```

#### 2. Bootstrap the Avocado environment (host (baremetal) only)

Do not pass `--enable-kvm` for host (baremetal) only runs:

```bash
python3 ./avocado-setup.py --bootstrap --install-deps --no-download
```

#### 3. Baremetal testcase layout

Tests are listed in `config/tests/host/VeLinux_elves.cfg` and implemented in
[avocado-misc-tests](https://github.com/AMDESE/avocado-misc-tests/tree/downstream) on the `downstream` branch. See the main README for per-feature directories and test README files.

#### 4. Run the testcases

Set testcase inputs per each test README and `VeLinux_elves.cfg`, then run:

```bash
python3 ./avocado-setup.py --nrunner --run-suite host_VeLinux_elves --no-download
```

### Issues

Report downstream distro issues in [AMDESE/elves](https://github.com/AMDESE/elves/issues).
