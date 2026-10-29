SUMMARY = "Minimal console test image for Next Thing Co. C.H.I.P."
DESCRIPTION = "A small, fast-booting console-only image providing core system tools."
LICENSE = "MIT"

IMAGE_INSTALL = " \
    packagegroup-core-boot \
    ${CORE_IMAGE_EXTRA_INSTALL} \
    kernel-modules \
    e2fsprogs-resize2fs \
    parted \
"

inherit core-image

IMAGE_ROOTFS_SIZE ?= "65536"
IMAGE_ROOTFS_EXTRA_SPACE:append = "${@bb.utils.contains("IMAGE_FSTYPES", "ubi", " + 16384", "", d)}"

