#!/bin/bash

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo "Cannot detect OS. Exiting."
        exit 1
    fi
}

install_prereq() {
    case $OS in
        ubuntu)
            echo "Installing required packages on Ubuntu"
            sudo apt-get update
            sudo apt-get install -y libguestfs-tools seabios isc-dhcp-client qemu-utils qemu-system-x86
            ;;
        rhel|centos)
            echo "Installing required packages on RHEL/CentOS"
            sudo yum install -y guestfs-tools dhcp-client seabios qemu-img qemu-kvm
            ;;
        *)
            echo "Unsupported OS: $OS. Exiting."
            exit 1
            ;;
    esac

    if [ $? -ne 0 ]; then
        echo "Failed to install the required packages. Please install ${missing_bins[*]} and rerun the script."
        exit 1
    fi
}
missing_bins=()
for bin in virt-customize dhclient qemu-img; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        missing_bins+=("$bin")
    fi
done
if [ ${#missing_bins[@]} -gt 0 ]; then
    echo "Required binaries not found: ${missing_bins[*]}. Attempting to install required packages:"
    detect_os
    install_prereq
fi
#Remove any old images by the same name
rm -f noble-server-cloudimg-amd64.{img,qcow2} 2>/dev/null
#Download Ubuntu 24.04 cloud image (version 20250430, tested)
image_url="https://cloud-images.ubuntu.com/noble/20250430/noble-server-cloudimg-amd64.img"
image_file="noble-server-cloudimg-amd64.img"
wget "$image_url" -O "$image_file" || { echo "Failed to download image"; exit 1; }
export LIBGUESTFS_BACKEND=direct
# Create and resize QCOW2 image to 10GB
qemu-img create -f qcow2 -o preallocation=metadata noble-server-cloudimg-amd64.qcow2 10G || {
    echo "Failed to create QCOW2 image"; exit 1;
}
echo "Expanding the root disk size to 10GB:"
virt-resize --expand /dev/sda1 noble-server-cloudimg-amd64.img noble-server-cloudimg-amd64.qcow2 || {
    echo "virt-resize failed"; exit 1;
}
# Clean up the original image
rm -f noble-server-cloudimg-amd64.img 2>/dev/null
echo "Customizing image with virt-customize:"
virt-customize -a noble-server-cloudimg-amd64.qcow2 \
    --uninstall cloud-init \
    --root-password password:12345678 \
    --install isc-dhcp-client,isc-dhcp-client-ddns,openssh-server,grub2 \
    --copy-in guest_network.yaml:/etc/netplan/ \
    --run-command 'sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config' \
    --run-command 'sed -i "s/#PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config' \
    --run-command 'ssh-keygen -A' \
    --run-command 'systemctl enable ssh' \
    --run-command 'grub-install /dev/sda' \
    --run-command 'update-grub' \
    --delete '/etc/ssh/sshd_config.d/*cloudimg-settings.conf'

if [ $? -eq 0 ]; then
    echo "Image noble-server-cloudimg-amd64.qcow2 ready to use."
else
    echo "Image creation failed."
    exit 1
fi

exit 0
