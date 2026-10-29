#!/usr/bin/env bash
#
# Helper script to flash or test-boot Next Thing Co. C.H.I.P. using sunxi-fel
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="${1:-$SCRIPT_DIR/../build/tmp/deploy/images/chip}"

echo "======================================================"
echo " Next Thing Co. C.H.I.P. Mainline Linux FEL Tool"
echo "======================================================"

if ! command -v sunxi-fel &> /dev/null; then
    echo "Error: 'sunxi-fel' tool is not found."
    echo "Install it on Debian/Ubuntu with:"
    echo "  sudo apt-get install sunxi-tools"
    exit 1
fi

echo "Checking for C.H.I.P. in FEL mode..."
echo "Tip: To enter FEL mode, jumper pin 7 (FEL) on header U14 to GND (pin 1 or 2)"
echo "     and connect the Micro-USB cable to your PC."
echo ""

if ! sunxi-fel ver 2>/dev/null; then
    echo "No Allwinner device detected in FEL mode. Please check cable and jumper."
    exit 1
fi

echo "Device detected successfully!"
echo ""
echo "Select an action:"
echo "  1) RAM Boot (Test boot modern kernel & DTB directly without touching NAND)"
echo "  2) Flash modern U-Boot SPL and U-Boot to onboard NAND"
echo "  3) Exit"
echo ""
read -rp "Enter choice [1-3]: " CHOICE

case "$CHOICE" in
    1)
        echo "Starting RAM boot..."
        if [ ! -f "$DEPLOY_DIR/sunxi-spl.bin" ] || [ ! -f "$DEPLOY_DIR/u-boot.bin" ] || [ ! -f "$DEPLOY_DIR/zImage" ]; then
            echo "Error: Missing build artifacts in $DEPLOY_DIR"
            echo "Required: sunxi-spl.bin, u-boot.bin, zImage, sun5i-r8-chip.dtb"
            exit 1
        fi

        DTB="$DEPLOY_DIR/sun5i-r8-chip.dtb"
        if [ ! -f "$DTB" ]; then
            DTB="$DEPLOY_DIR/allwinner/sun5i-r8-chip.dtb"
        fi

        echo "Uploading SPL..."
        sunxi-fel spl "$DEPLOY_DIR/sunxi-spl.bin"
        sleep 1

        echo "Uploading U-Boot (0x4a000000)..."
        sunxi-fel write 0x4a000000 "$DEPLOY_DIR/u-boot.bin"

        echo "Uploading Device Tree (0x43000000)..."
        sunxi-fel write 0x43000000 "$DTB"

        echo "Uploading Linux Kernel zImage (0x42000000)..."
        sunxi-fel write 0x42000000 "$DEPLOY_DIR/zImage"

        echo "Executing U-Boot..."
        sunxi-fel exe 0x4a000000
        echo "Kernel booted into RAM! Connect a serial cable to UART0 (115200 baud) to view output."
        ;;
    2)
        echo "Flashing modern U-Boot..."
        echo "Please ensure U-Boot binary is present in $DEPLOY_DIR"
        # Flashing raw NAND requires fastboot or u-boot nand write
        echo "For reliable NAND flashing, run modern U-Boot via FEL and use U-Boot's 'nand write' command."
        ;;
    3)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo "Invalid selection."
        exit 1
        ;;
esac

