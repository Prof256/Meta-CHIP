SECTION = "kernel"
DESCRIPTION = "Modern mainline Linux kernel for Next Thing Co. C.H.I.P."
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

inherit kernel

PV = "6.6.21"

SRC_URI = " \
    https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${PV}.tar.xz \
    file://defconfig \
"
SRC_URI[sha256sum] = "ee0b430148da94d2b13608b8d80b007b7d281dc90e3f19b63cf9a9943810e457"

S = "${WORKDIR}/linux-${PV}"

COMPATIBLE_MACHINE = "chip"

# Ensure convenience symlinks in deploy directory for U-Boot and flashing tools
do_deploy:append() {
    if [ -f ${DEPLOYDIR}/sun5i-r8-chip.dtb ]; then
        install -d ${DEPLOYDIR}/allwinner
        ln -sf ../sun5i-r8-chip.dtb ${DEPLOYDIR}/allwinner/sun5i-r8-chip.dtb
    elif [ -f ${DEPLOYDIR}/allwinner/sun5i-r8-chip.dtb ]; then
        ln -sf allwinner/sun5i-r8-chip.dtb ${DEPLOYDIR}/sun5i-r8-chip.dtb
    fi
}

