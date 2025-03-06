# **<span class="underline">Bare Metal (BM)</span>**
Bare Metal (BM) involves testing on physical machines without any hypervisor or virtualization software.

# **<span class="underline">Prerequisites:</span>**

1. **Avocado:** Avocado is a set of tools and libraries to help with automated testing. These tools
include test runners, libraries, and result logging capabilities that help users to write
tests.
2. **Avocado miscellaneous:** Avocado-misc-tests is a dedicated host for any tests written using
the Avocado API. This repository houses all baremetal test cases.



# **<span class="underline">Setup Avocado and Avocado miscellaneous:</span>**

1. Install the following dependencies:
```
    xz-utils tcpdump iproute2 iputils-ping gcc libc6-dev netcat-traditional git python3-pip libosinfo-1.0-0

```

2. Follow the below steps to install the avocado framework in a python virtual environment:
```
    apt install python3-venv
    mkdir ~/py_avocado_venv
    python3 -m venv  ~/py_avocado_venv
    source ~/py_avocado_venv/bin/activate
    (py_avocado_venv) # pip3 install avocado-framework==103.0
    (py_avocado_venv) # pip3 install avocado-framework-plugin-result-html==103.0
    (py_avocado_venv) # pip3 install avocado-framework-plugin-varianter-yaml-to-mux==103.0
    (py_avocado_venv) # which avocado
    (py_avocado_venv) # echo 'export PATH=$PATH:~/py_avocado_venv/bin' >> ~/.bashrc
    (py_avocado_venv) # deactivate
    Logout and login back to the terminal
```


**Note:** If the user doesn't want to use a python virtual environment for avocado setup, follow below steps.
Append --break-system-packages if you are using pip v23.1 or later in your environment.
```
    pip3 install avocado-framework==103.0
    pip3 install avocado-framework-plugin-result-html==103.0
    pip3 install avocado-framework-plugin-varianter-yaml-to-mux==103.0
```

3. Clone the 'avocado-misc-tests' repository.
```
    git clone https://github.com/avocado-framework-tests/avocado-misc-tests.git
```

4. Run Baremetal (BM) tests for the features mentioned below by following the respective feature README.md files.



# **<span class="underline">Features</span>**

1. **iommu:** Covers IOMMU tests, the details can be found in [iommu/README.md](iommu/README.md).
2. **pqos:** Covers PQOS CPUID, MSR check and functionality tests, the details can be found in [pqos/README.md](pqos/README.md).
3. **ras/mce\_mca:** Covers RAS mce, mca tests, the details can be found in [ras/mce\_mca/README.md](ras/mce\_mca/README.md).
