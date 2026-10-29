# Modern U-Boot boot script for Next Thing Co. C.H.I.P.
echo "=== Next Thing Co. C.H.I.P. Modern Linux Bootloader ==="

setenv console ttyS0,115200
setenv kernel_addr_r 0x42000000
setenv fdt_addr_r 0x43000000

# 1. Try USB drive boot (Priority 1: Easiest & Most Reliable)
if usb start; then
    echo "Checking for bootable USB storage..."
    if test -e usb 0:1 /boot/zImage; then
        echo "Found Linux kernel on USB device 0:1 (/boot/zImage)"
        setenv bootargs console=${console} root=/dev/sda1 rootwait rw panic=10
        load usb 0:1 ${kernel_addr_r} /boot/zImage
        if load usb 0:1 ${fdt_addr_r} /boot/sun5i-r8-chip.dtb; then
            bootz ${kernel_addr_r} - ${fdt_addr_r}
        elif load usb 0:1 ${fdt_addr_r} /boot/allwinner/sun5i-r8-chip.dtb; then
            bootz ${kernel_addr_r} - ${fdt_addr_r}
        fi
    fi
fi

# 2. Try Onboard NAND Flash (UBI / UBIFS)
echo "Checking onboard NAND UBI partition..."
if ubi part rootfs; then
    if ubifsmount ubi0:rootfs; then
        echo "Mounted UBIFS volume ubi0:rootfs successfully"
        setenv bootargs console=${console} ubi.mtd=rootfs root=ubi0:rootfs rootfstype=ubifs rw panic=10
        ubifsload ${kernel_addr_r} /boot/zImage
        if ubifsload ${fdt_addr_r} /boot/sun5i-r8-chip.dtb; then
            bootz ${kernel_addr_r} - ${fdt_addr_r}
        elif ubifsload ${fdt_addr_r} /boot/allwinner/sun5i-r8-chip.dtb; then
            bootz ${kernel_addr_r} - ${fdt_addr_r}
        fi
    fi
fi

echo "Error: Boot failed. No valid kernel found on USB (sda1) or onboard NAND."

