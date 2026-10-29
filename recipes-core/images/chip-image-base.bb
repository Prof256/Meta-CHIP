SUMMARY = "Feature-rich embedded Linux image for Next Thing Co. C.H.I.P."
DESCRIPTION = "An embedded Linux image for C.H.I.P. with WiFi, Bluetooth, \
SSH server, USB OTG gadget networking, and hardware debugging utilities."
LICENSE = "MIT"

IMAGE_FEATURES += "ssh-server-dropbear package-management"

IMAGE_INSTALL = " \
    packagegroup-core-boot \
    packagegroup-core-full-cmdline \
    ${CORE_IMAGE_EXTRA_INSTALL} \
    \
    # Hardware & Kernel \
    kernel-modules \
    kernel-devicetree \
    u-boot-chip \
    \
    # Wireless & Bluetooth Networking \
    iw \
    wpa-supplicant \
    wireless-regdb-static \
    bluez5 \
    \
    # Hardware Debugging & Bus Utilities \
    i2c-tools \
    usbutils \
    evtest \
    mtd-utils \
    mtd-utils-ubifs \
    \
    # Storage & System Utilities \
    e2fsprogs \
    e2fsprogs-resize2fs \
    parted \
    dosfstools \
    htop \
    nano \
    sudo \
"

inherit core-image

IMAGE_ROOTFS_SIZE ?= "262144"

