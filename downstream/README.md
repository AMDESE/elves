### ELVES downstream distributions

Downstream host OS support is documented here. The upstream Ubuntu
host/guest and virtualization flow is unchanged in the [top-level
README](../README.md) (guest distro, KVM/QEMU/OVMF versions, guest testcase list, and KVM references remain there).

Use the **`downstream`** branch for flows in this file.

### Supported downstream host operating systems

| Host OS | Scope | os-release `ID` | Host config file | Avocado run suite |
|---------|-------|-----------------|------------------|-------------------|
| veLinux-2.2 | Host (baremetal) only | `debian` | `config/tests/host/veLinux_elves.cfg` | `host_veLinux_elves` |
| Anolis OS 23.5 | Host (baremetal) only | `anolis` | `config/tests/host/Anolis_elves.cfg` | `host_Anolis_elves` |
| openEuler 24.03 (LTS) | Host (baremetal) only | `openEuler` | `config/tests/host/openEuler_elves.cfg` | `host_openEuler_elves` |
| OpenCloudOS 9.4 | Host (baremetal) only | `opencloudos` | `config/tests/host/OpenCloudOS_elves.cfg` | `host_OpenCloudOS_elves` |

Each distro uses its own `<Distro>_elves.cfg` with run suite `host_<Distro>_elves`. The run steps below are
identical for every supported host OS — substitute the **Host config file** and
**Avocado run suite** for your distro from this table.

### Downstream validated component versions

The testcase sets in distro-specific config files are validated against the component levels below.
Structure matches the upstream **Supported component versions** section in the top-level README.
All downstream host OSes are host (baremetal) only for now.

#### veLinux-2.2

Validated against `config/tests/host/veLinux_elves.cfg` / `--run-suite host_veLinux_elves`:

- **Baremetal OS kernel**: 6.6.95.ve.3-amd64 (https://github.com/openvelinux/kernel/tree/v6.6.95.ve.3, commit c59b892d042); also validated with upstream kernel v7.0.10

#### Anolis OS 23.5

Validated against `config/tests/host/Anolis_elves.cfg` / `--run-suite host_Anolis_elves`:

- **Baremetal OS kernel**: 6.6.102 (Repo: https://gitee.com/anolis/cloud-kernel.git [branch: devel-6.6] [commit id: e7011e86f7e9]); also validated with upstream kernel v7.0.10

#### openEuler 24.03 (LTS)

Validated against `config/tests/host/openEuler_elves.cfg` / `--run-suite host_openEuler_elves`:

- **Baremetal OS kernel**: 6.6.0-145.0.13.139.oe2403.x86_64 (openEuler 24.03 LTS); also validated with upstream kernel v6.19.4

#### OpenCloudOS 9.4

Validated against `config/tests/host/OpenCloudOS_elves.cfg` / `--run-suite host_OpenCloudOS_elves`:

- **Baremetal OS kernel**: 6.6.119-49.21.oc9.x86_64 (OpenCloudOS 9.4); also validated with upstream kernel v6.19.4

### Steps to run the testcases

These steps are the same for every supported downstream host OS. In the commands below,
replace `<Distro>_elves.cfg` and `host_<Distro>_elves` with the values for your host OS from the
**Supported downstream host operating systems** table above (for example `veLinux_elves.cfg` /
`host_veLinux_elves`, `Anolis_elves.cfg` / `host_Anolis_elves`,
`openEuler_elves.cfg` / `host_openEuler_elves`, or
`OpenCloudOS_elves.cfg` / `host_OpenCloudOS_elves`).

##### Note: Tests should be run with superuser permissions.

#### Prerequisites

1. Host running a supported downstream OS (see table) on supported AMD EPYC hardware (see main README **Supported Hardware**).
2. Repository on branch **`downstream`**.
3. **python3** and **python3-pip** installed on the host.
4. A host package section in **`config/wrapper/env.conf`**. Bootstrap selects it from your
   `/etc/os-release` `ID`: an `ID`+major-version section (for example `[deps_debian13]`) is tried
   first, then it falls back to `[deps_<ID>]`. Add `[deps_<ID>]` for your OS — for example
   `[deps_debian]` for veLinux (`ID=debian`), `[deps_anolis]` for Anolis (`ID=anolis`),
   `[deps_openEuler24]` for openEuler 24.03 (`ID=openEuler`), and `[deps_opencloudos9]` for
   OpenCloudOS 9.4 (`ID=opencloudos`).

#### 1. Clone the repository

```bash
git clone -b downstream https://github.com/AMDESE/elves.git
cd elves
```

#### 2. Bootstrap the Avocado environment

Do not pass `--enable-kvm` for host (baremetal) only runs:

```bash
python3 ./avocado-setup.py --bootstrap --install-deps --no-download
```

#### 3. Baremetal testcase layout

Tests are listed in your distro's `config/tests/host/<Distro>_elves.cfg` and implemented in
[avocado-misc-tests](https://github.com/AMDESE/avocado-misc-tests/tree/downstream) on the `downstream` branch. See the main README for per-feature directories and test README files.

#### 4. Run the testcases

Set testcase inputs per each test README and your `<Distro>_elves.cfg`, then run:

```bash
python3 ./avocado-setup.py --nrunner --run-suite host_<Distro>_elves --no-download
```

### Issues

Report downstream distro issues in [AMDESE/elves](https://github.com/AMDESE/elves/issues).
