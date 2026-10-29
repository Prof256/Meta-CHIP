#!/usr/bin/env bash
#
# Create a bootable USB drive for Next Thing Co. C.H.I.P.
#
set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: sudo $0 /dev/sdX <path-to-image-tar.gz-or-ext4>"
    echo "Example: sudo $0 /dev/sdb build/tmp/deploy/images/chip/chip-image-minimal-chip.rootfs.tar.gz"
    exit 1
fi

DISK="$1"
ROOTFS_ARCHIVE="$2"

if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo)."
    exit 1
fi

if [ ! -b "$DISK" ]; then
    echo "Error: Device $DISK is not a block device."
    exit 1
fi

echo "WARNING: All data on $DISK will be permanently erased!"
read -rp "Are you sure you want to format $DISK? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo "1. Partitioning $DISK..."
parted -s "$DISK" mklabel msdos
parted -s "$DISK" mkpart primary ext4 1MiB 100%

PART="${DISK}1"
if [[ "$DISK" =~ [0-9]$ ]]; then
    PART="${DISK}p1"
fi

echo "2. Formatting $PART as ext4..."
mkfs.ext4 -F -L "chip-root" "$PART"

MOUNT_DIR=$(mktemp -d)
echo "3. Mounting $PART to $MOUNT_DIR..."
mount "$PART" "$MOUNT_DIR"

echo "4. Extracting root filesystem..."
if [[ "$ROOTFS_ARCHIVE" == *.tar.gz ]]; then
    tar -xzf "$ROOTFS_ARCHIVE" -C "$MOUNT_DIR"
elif [[ "$ROOTFS_ARCHIVE" == *.tar.bz2 ]]; then
    tar -xjf "$ROOTFS_ARCHIVE" -C "$MOUNT_DIR"
elif [[ "$ROOTFS_ARCHIVE" == *.ext4 ]]; then
    LOOP_DIR=$(mktemp -d)
    mount -o loop "$ROOTFS_ARCHIVE" "$LOOP_DIR"
    cp -a "$LOOP_DIR"/* "$MOUNT_DIR"/
    umount "$LOOP_DIR"
    rmdir "$LOOP_DIR"
else
    echo "Unsupported archive format: $ROOTFS_ARCHIVE"
    umount "$MOUNT_DIR"
    rmdir "$MOUNT_DIR"
    exit 1
fi

sync
echo "5. Unmounting $PART..."
umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"

echo "Done! USB drive is ready. Plug it into the C.H.I.P.'s USB port and boot."

