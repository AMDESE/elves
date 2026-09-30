#!/bin/bash

default_image_url="https://cloud-images.ubuntu.com/resolute/20260823/resolute-server-cloudimg-amd64.img"
image_source=""
image_mode=""
disk_size="10G"
guest_root_password="${GUEST_ROOT_PASSWORD:-12345678}"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create a customized guest disk image for virtualization tests."
    echo ""
    echo "Options:"
    echo "  --image-path <path>   Use a local disk image (e.g. .img or .qcow2)"
    echo "  --image-url <url>     Download image from URL (default: Ubuntu 24.04 cloud image)"
    echo "  --disk-size <size>    Resize disk to <size> (e.g. 10G, 20G; default: 10G)"
    echo "  -h, --help            Show this help and exit"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use default Ubuntu cloud image"
    echo "  $0 --image-path /path/to/my.qcow2"
    echo "  $0 --image-url https://cloud-images.ubuntu.com/..."
}

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
            sudo apt-get install -y libguestfs-tools seabios qemu-utils qemu-system-x86
            ;;
        rhel|centos)
            echo "Installing required packages on RHEL/CentOS"
            sudo yum install -y guestfs-tools seabios qemu-img qemu-kvm
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
for bin in virt-customize qemu-img; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        missing_bins+=("$bin")
    fi
done
if [ ${#missing_bins[@]} -gt 0 ]; then
    echo "Required binaries not found: ${missing_bins[*]}. Attempting to install required packages:"
    detect_os
    install_prereq
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        --image-path)
            [ -n "$image_source" ] && { echo "Use only one of --image-path or --image-url"; exit 1; }
            [ -z "$2" ] && { echo "Error: --image-path requires a value"; usage; exit 1; }
            image_source="$2"
            image_mode="local"
            shift 2
            ;;
        --image-url)
            [ -n "$image_source" ] && { echo "Use only one of --image-path or --image-url"; exit 1; }
            [ -z "$2" ] && { echo "Error: --image-url requires a value"; usage; exit 1; }
            image_source="$2"
            image_mode="url"
            shift 2
            ;;
        --disk-size)
            [ -z "$2" ] && { echo "Error: --disk-size requires a value"; usage; exit 1; }
            disk_size="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done
if [ -z "$image_source" ]; then
    image_source="$default_image_url"
    image_mode="url"
fi

if [ "$image_mode" = "url" ]; then
    image_url="$image_source"
    image_file=$(basename "$image_url")
    echo "Downloading image from $image_url"
    rm -f "$image_file" "${image_file%.*}"*.qcow2 2>/dev/null
    wget "$image_url" -O "$image_file" || { echo "Failed to download image"; exit 1; }
elif [ "$image_mode" = "local" ]; then
    if [ ! -f "$image_source" ]; then
        echo "Local image not found: $image_source"
        exit 1
    fi
    image_file=$(basename "$image_source")
    echo "Using local image: $image_source"
    if [ "$(readlink -f -- "$image_source")" != "$(readlink -f -- "./$image_file")" ]; then
        rm -f "$image_file" "${image_file%.*}"*.qcow2 2>/dev/null
        cp "$image_source" "$image_file" || { echo "Failed to copy image"; exit 1; }
    fi
fi

export LIBGUESTFS_BACKEND=direct

image_fmt=$(qemu-img info "$image_file" 2>/dev/null | awk '/^file format:/ { print $3; exit }')
if [[ "$image_fmt" != "raw" && "$image_fmt" != "qcow2" ]]; then
    echo "Unsupported image format '${image_fmt:-unknown}' for $image_file. Only qcow2 and raw are supported. Exiting."
    exit 1
fi

if ! qemu-img resize "$image_file" "$disk_size" 2>&1; then
    echo "qemu-img resize failed (image: $image_file, size: $disk_size). Exiting."
    echo "Hint: --disk-size must not be smaller than the source image; use a larger size or the default."
    exit 1
fi

image_renamed="${image_file%.*}.${image_fmt}"
if [[ "$image_file" != "$image_renamed" ]]; then
    mv "$image_file" "$image_renamed"
    echo "Image format is $image_fmt; renamed $image_file -> $image_renamed"
    image_file="$image_renamed"
fi

read_guest_os_release() {
    _guest_os_release=""
    local _path
    for _path in /etc/os-release /usr/lib/os-release; do
        _guest_os_release=$(virt-cat -a "$image_file" "$_path" 2>/dev/null) || continue
        [ -n "$_guest_os_release" ] && return 0
    done
    return 1
}

read_guest_os_release || true
GUEST_ID=$(printf '%s\n' "$_guest_os_release" | sed -n 's/^ID=\(.*\)/\1/p' | tr -d '"' | head -1)
GUEST_ID_LIKE=$(printf '%s\n' "$_guest_os_release" | sed -n 's/^ID_LIKE=\(.*\)/\1/p' | tr -d '"' | head -1)
if [ -z "$GUEST_ID" ]; then
    echo "Unable to determine the distribution (could not read /etc/os-release from image)."
    echo "Hint: use a preinstalled cloud/rootfs disk image (.img/.qcow2), not installer or live ISO;"
    echo "      host libguestfs must be able to access the image (unsupported filesystem or layout may block this)."
    exit 1
fi
case "$(printf '%s' "$GUEST_ID" | tr '[:upper:]' '[:lower:]')" in
    rhel|centos|rocky|almalinux|ol|fedora|openeuler) GUEST_FAMILY="rhel" ;;
    ubuntu|debian) GUEST_FAMILY="ubuntu" ;;
    *)
        _guest_id_like_rhel=0
        for _guest_id_like_word in $GUEST_ID_LIKE; do
            if [ "$_guest_id_like_word" = "rhel" ]; then
                _guest_id_like_rhel=1
                break
            fi
        done
        if [ "$_guest_id_like_rhel" -eq 1 ]; then
            GUEST_FAMILY="rhel"
        else
            echo "Unsupported guest OS: '$GUEST_ID' (ID_LIKE='$GUEST_ID_LIKE'). Only Ubuntu/Debian and RHEL derivatives are supported."
            exit 1
        fi
        ;;
esac

detect_root_layout() {
    ROOT_DEV=""
    FSTAB_ROOT_SPEC=""
    if virt-cat -a "$image_file" /etc/fstab >/dev/null 2>&1; then
        ROOT_DEV=$(virt-cat -a "$image_file" /etc/fstab 2>/dev/null | awk '!/^[[:space:]]*#/ && NF >= 2 && $2 == "/" { print $1; exit }')
    fi
    FSTAB_ROOT_SPEC="$ROOT_DEV"

    # Map UUID=/LABEL= for / to a concrete /dev/… path.
    if [ -n "$ROOT_DEV" ]; then
        case "$ROOT_DEV" in
            [Uu][Uu][Ii][Dd]=*)
                _uuid="${ROOT_DEV#*=}"
                _uuid="${_uuid//\"/}"
                _resolved=$(
                    virt-filesystems -a "$image_file" --all --uuid --long --no-title 2>/dev/null \
                        | awk -v u="$_uuid" '$2 == "filesystem" && tolower($NF) == tolower(u) { print $1; exit }'
                )
                [ -n "$_resolved" ] && ROOT_DEV="$_resolved"
                ;;
            [Ll][Aa][Bb][Ee][Ll]=*)
                _lab="${ROOT_DEV#*=}"
                _lab="${_lab//\"/}"
                _resolved=$(
                    virt-filesystems -a "$image_file" --all --uuid --long --no-title 2>/dev/null \
                        | awk -v lab="$_lab" '$2 == "filesystem" && $4 == lab { print $1; exit }'
                )
                [ -n "$_resolved" ] && ROOT_DEV="$_resolved"
                ;;
        esac
    fi

    USE_LVM=""
    VG_NAME=""
    ROOT_DISK=""
    ROOT_PART_NUM=""
    ROOT_PART_DEV=""
    if [ -n "$ROOT_DEV" ]; then
        case "$ROOT_DEV" in
            /dev/mapper/*)
                USE_LVM=1
                VG_NAME="${ROOT_DEV#/dev/mapper/}"
                VG_NAME="${VG_NAME%-*}"
                ;;
            /dev/*/root)
                USE_LVM=1
                VG_NAME="${ROOT_DEV#/dev/}"
                VG_NAME="${VG_NAME%/root}"
                ;;
            /dev/nvme*n*p*)
                ROOT_PART_DEV="$ROOT_DEV"
                ROOT_DISK="${ROOT_DEV%p*}"
                ROOT_DISK="${ROOT_DISK#/dev/}"
                ROOT_PART_NUM="${ROOT_DEV##*p}"
                ;;
            /dev/sd[a-z]*|/dev/vd[a-z]*|/dev/xvd[a-z]*)
                ROOT_PART_DEV="$ROOT_DEV"
                ROOT_PART_NUM="${ROOT_DEV##*[!0-9]}"
                ROOT_DISK="${ROOT_DEV%[0-9]*}"
                ROOT_DISK="${ROOT_DISK#/dev/}"
                ;;
            /dev/*/*)
                if virt-filesystems -a "$image_file" --logical-volumes 2>/dev/null | grep -qx "$ROOT_DEV"; then
                    USE_LVM=1
                    VG_NAME="${ROOT_DEV#/dev/}"
                    VG_NAME="${VG_NAME%%/*}"
                fi
                ;;
        esac
    fi

    if [ -n "$FSTAB_ROOT_SPEC" ] && [ "$ROOT_DEV" = "$FSTAB_ROOT_SPEC" ]; then
        case "$FSTAB_ROOT_SPEC" in
            [Uu][Uu][Ii][Dd]=*|[Ll][Aa][Bb][Ee][Ll]=*)
                echo "Could not resolve fstab root $FSTAB_ROOT_SPEC to a block device (virt-filesystems). Check /etc/fstab and image layout."
                exit 1
                ;;
        esac
    fi
    if [ -n "$FSTAB_ROOT_SPEC" ] && [ "$ROOT_DEV" != "$FSTAB_ROOT_SPEC" ]; then
        echo "Resolved fstab / ($FSTAB_ROOT_SPEC) to $ROOT_DEV for grow/resize."
    fi

    # Fallback: check for LVM via virt-filesystems, then infer disk + partition by family
    if [ -z "$USE_LVM" ] && [ -z "$ROOT_PART_DEV" ]; then
        LV_ROOT=$(virt-filesystems -a "$image_file" --logical-volumes 2>/dev/null | grep -E '/root$|/lv_root$' | head -1)
        if [ -n "$LV_ROOT" ]; then
            USE_LVM=1
            VG_NAME="${LV_ROOT#/dev/}"
            VG_NAME="${VG_NAME%/root}"
            VG_NAME="${VG_NAME%/lv_root}"
        else
            ROOT_DISK=$(virt-filesystems -a "$image_file" 2>/dev/null | grep -oE '^/dev/((sd|vd|xvd)[a-z]|nvme[0-9]+n[0-9]+)' | sort -u | head -1 | sed 's|^/dev/||')
            ROOT_DISK="${ROOT_DISK:-sda}"
            if [ "$GUEST_FAMILY" = "rhel" ]; then
                ROOT_PART_NUM=3
            else
                ROOT_PART_NUM=1
            fi
            if [[ "$ROOT_DISK" == nvme* ]]; then
                ROOT_PART_DEV="/dev/${ROOT_DISK}p${ROOT_PART_NUM}"
            else
                ROOT_PART_DEV="/dev/${ROOT_DISK}${ROOT_PART_NUM}"
            fi
        fi
    fi

    # Build disk resize command for virt-customize
    if [ -n "$USE_LVM" ] && [ -n "$VG_NAME" ]; then
        # Resolve LV name for lvextend/resize2fs: Find the logical volume path for /.
        LV_NAME=""
        ROOT_LV_PATH=""
        _guest_lvs=$(virt-filesystems -a "$image_file" --logical-volumes 2>/dev/null)
        if [ -n "$ROOT_DEV" ] && echo "$_guest_lvs" | grep -qx "$ROOT_DEV"; then
            ROOT_LV_PATH="$ROOT_DEV"
        elif [ -n "${LV_ROOT:-}" ] && echo "$_guest_lvs" | grep -qx "$LV_ROOT"; then
            ROOT_LV_PATH="$LV_ROOT"
        elif command -v virt-lvs >/dev/null 2>&1 && [ -n "$ROOT_DEV" ]; then
            ROOT_LV_PATH=$(
                virt-lvs -a "$image_file" --noheadings -o vg_name,lv_name,lv_path 2>/dev/null \
                    | awk -v d="$ROOT_DEV" '
                        NF >= 2 {
                            vg = $1
                            lv = $2
                            lvp = (NF >= 3 && $3 != "") ? $3 : "/dev/" vg "/" lv
                            if (lvp == d || "/dev/" vg "/" lv == d) {
                                print "/dev/" vg "/" lv
                                exit
                            }
                        }'
            )
        fi
        if [ -n "$ROOT_LV_PATH" ]; then
            VG_NAME="${ROOT_LV_PATH#/dev/}"
            LV_NAME="${VG_NAME##*/}"
            VG_NAME="${VG_NAME%/*}"
        elif [[ "$ROOT_DEV" == /dev/mapper/* ]] && [ -n "$VG_NAME" ]; then
            # When lv_path was not matched (e.g. only /dev/mapper/VG-LV is known): strip "<vg>-" from the dm name.
            # Fails if VG or LV names contain hyphens; then fstab/virt-lvs should supply /dev/VG/LV instead.
            _dm="${ROOT_DEV#/dev/mapper/}"
            LV_NAME="${_dm#"${VG_NAME}"-}"
            [ "$LV_NAME" = "$_dm" ] && LV_NAME=""
        fi
        [ -z "$LV_NAME" ] && LV_NAME="root"

        PV_DEV=$(virt-filesystems -a "$image_file" --physical-volumes 2>/dev/null | grep -E '^/dev/(sd|vd|xvd|nvme)' | head -1)
        if [ -z "$PV_DEV" ]; then
            ROOT_DISK="${ROOT_DISK:-sda}"
            PV_DEV="/dev/${ROOT_DISK}2"
        fi
        if [[ "$PV_DEV" =~ ^/dev/(.*)p([0-9]+)$ ]]; then
            PV_DISK="/dev/${BASH_REMATCH[1]}"
            PV_PART_NUM="${BASH_REMATCH[2]}"
        else
            PV_PART_NUM="${PV_DEV##*[!0-9]}"
            PV_DISK="${PV_DEV%[0-9]*}"
        fi
        disk_resize_cmd="growpart ${PV_DISK} ${PV_PART_NUM}; pvresize ${PV_DEV}; lvextend -l +100%FREE /dev/${VG_NAME}/${LV_NAME}; resize2fs /dev/${VG_NAME}/${LV_NAME} 2>/dev/null; xfs_growfs / 2>/dev/null; true"
        echo "Detected root on LVM (VG: $VG_NAME, LV: $LV_NAME, PV: $PV_DEV). Will grow PV, extend LV, then resize FS."
    else
        ROOT_DISK="${ROOT_DISK:-sda}"
        ROOT_PART_NUM="${ROOT_PART_NUM:-1}"
        if [[ "$ROOT_DISK" == nvme* ]]; then
            ROOT_PART_DEV="${ROOT_PART_DEV:-/dev/${ROOT_DISK}p${ROOT_PART_NUM}}"
        else
            ROOT_PART_DEV="${ROOT_PART_DEV:-/dev/${ROOT_DISK}${ROOT_PART_NUM}}"
        fi
        disk_resize_cmd="growpart /dev/${ROOT_DISK} ${ROOT_PART_NUM}; resize2fs ${ROOT_PART_DEV} 2>/dev/null; xfs_growfs / 2>/dev/null; true"
        echo "Detected root on partition ${ROOT_PART_DEV}. Will grow partition and resize filesystem."
    fi

    # Disk for grub install (same as the one we resized)
    if [ -n "$USE_LVM" ] && [ -n "$VG_NAME" ]; then
        GRUB_DISK="${PV_DISK:-/dev/sda}"
    else
        GRUB_DISK="/dev/${ROOT_DISK}"
    fi
}

detect_root_layout

echo "Detected guest OS family: $GUEST_FAMILY (ID=$GUEST_ID)"
echo "Customizing image with virt-customize:"

if [ "$GUEST_FAMILY" = "rhel" ]; then
    virt-customize -a "$image_file" \
        --root-password "password:${guest_root_password}" \
        --run-command '[ -f /etc/securetty ] && { grep -qxF ttyS0 /etc/securetty || echo ttyS0 >> /etc/securetty; }; true' \
        --run-command 'sed -i "s/#*PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config; sed -i "s/#*PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config' \
        --run-command 'for pkg in cloud-init kdump-utils; do rpm -q "$pkg" >/dev/null 2>&1 && dnf -y remove "$pkg" 2>/dev/null; done; true' \
        --install openssh-server,cloud-utils-growpart,NetworkManager \
        --copy-in guest_network_rhel.nmconnection:/etc/NetworkManager/system-connections/ \
        --run-command 'chmod 600 /etc/NetworkManager/system-connections/guest_network_rhel.nmconnection' \
        --run-command 'systemctl enable NetworkManager' \
        --run-command "$disk_resize_cmd" \
        --run-command 'ssh-keygen -A' \
        --run-command 'systemctl enable sshd' \
        --run-command "if [ -e /usr/lib/grub/i386-pc/modinfo.sh ]; then grub2-install $GRUB_DISK; fi" \
        --run-command 'grub2-mkconfig -o /boot/grub2/grub.cfg'
    rc=$?
else
    virt-customize -a "$image_file" \
        --run-command 'for pkg in cloud-init kdump-tools cloud-initramfs-copymods cloud-initramfs-dyn-netconf; do dpkg -l "$pkg" 2>/dev/null | grep -q "^ii" && apt-get -q -y purge "$pkg" 2>/dev/null; done; true' \
        --run-command '[ -f /etc/securetty ] && { grep -qxF ttyS0 /etc/securetty || echo ttyS0 >> /etc/securetty; }; true' \
        --root-password "password:${guest_root_password}" \
        --install isc-dhcp-client,isc-dhcp-client-ddns,openssh-server \
        --copy-in guest_network_ubuntu.yaml:/etc/netplan/ \
        --run-command 'sed -i "s/#*PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config' \
        --run-command 'sed -i "s/#*PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config' \
        --run-command "$disk_resize_cmd" \
        --run-command 'ssh-keygen -A' \
        --run-command 'systemctl enable ssh' \
        --run-command 'systemctl disable --now unattended-upgrades.service 2>/dev/null; systemctl mask unattended-upgrades.service 2>/dev/null; systemctl disable --now apt-daily.timer apt-daily-upgrade.timer 2>/dev/null; true' \
        --run-command "grub-install $GRUB_DISK" \
        --run-command 'update-grub' \
        --delete '/etc/ssh/sshd_config.d/*cloudimg-settings.conf'
    rc=$?
fi

if [ $rc -eq 0 ]; then
    echo "Image $image_file ready to use."
else
    echo "Image creation failed."
    exit 1
fi
