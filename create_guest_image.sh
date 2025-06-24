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

#Download Ubuntu 24.04 cloud image (version 20250430, tested)
image_url="https://cloud-images.ubuntu.com/releases/noble/release-20250430/ubuntu-24.04-server-cloudimg-amd64.img"
image_file=$(basename $image_url)

#Remove any old images by the same name
rm -f $image_file ${image_file%.*}*.qcow2 2>/dev/null

wget "$image_url" -O "$image_file" || { echo "Failed to download image"; exit 1; }
export LIBGUESTFS_BACKEND=direct

mv $image_file ${image_file%.img}.qcow2
image_file=${image_file%.img}.qcow2

qemu-img resize $image_file 10G

echo "Customizing image with virt-customize:"
virt-customize -a $image_file \
    --uninstall cloud-init \
    --root-password password:12345678 \
    --install isc-dhcp-client,isc-dhcp-client-ddns,openssh-server,grub2 \
    --copy-in guest_network.yaml:/etc/netplan/ \
    --run-command 'sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config' \
    --run-command 'sed -i "s/#PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config' \
    --run-command 'growpart /dev/sda 1' \
    --run-command 'resize2fs /dev/sda1' \
    --run-command 'ssh-keygen -A' \
    --run-command 'systemctl enable ssh' \
    --run-command 'grub-install /dev/sda' \
    --run-command 'update-grub' \
    --delete '/etc/ssh/sshd_config.d/*cloudimg-settings.conf'

if [ $? -eq 0 ]; then
    echo "Image $image_file ready to use."
else
    echo "Image creation failed."
    exit 1
fi

exit 0
