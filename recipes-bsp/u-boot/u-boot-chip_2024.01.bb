require recipes-bsp/u-boot/u-boot.inc

DESCRIPTION = "Modern U-Boot bootloader for Next Thing Co. C.H.I.P."
HOMEPAGE = "http://www.denx.de/wiki/U-Boot/WebHome"
LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=2ca5f2c35c8cc335f0a19756634782f1"

PV = "2024.01"
SRC_URI = "https://ftp.denx.de/pub/u-boot/u-boot-${PV}.tar.bz2 \
           file://boot.cmd \
          "
SRC_URI[sha256sum] = "b99611f1ed237bf3541bdc8434b68c96a6e05967061f992443cb30aabebef5b3"

S = "${WORKDIR}/u-boot-${PV}"

DEPENDS += "bc-native dtc-native u-boot-tools-native"
PROVIDES += "u-boot"

COMPATIBLE_MACHINE = "chip"

do_compile:append() {
    ${B}/tools/mkimage -C none -A arm -T script -d ${WORKDIR}/boot.cmd ${B}/boot.scr
}

do_install:append() {
    install -d ${D}/boot
    install -m 0644 ${B}/boot.scr ${D}/boot/boot.scr
}

do_deploy:append() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${B}/boot.scr ${DEPLOYDIR}/boot.scr

    if [ -f ${B}/u-boot-sunxi-with-spl.bin ]; then
        install -m 0644 ${B}/u-boot-sunxi-with-spl.bin ${DEPLOYDIR}/u-boot-sunxi-with-spl.bin
    fi
    if [ -f ${B}/spl/sunxi-spl.bin ]; then
        install -m 0644 ${B}/spl/sunxi-spl.bin ${DEPLOYDIR}/sunxi-spl.bin
    fi
}

FILES:${PN} += "/boot/boot.scr"

