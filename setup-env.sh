#!/usr/bin/env bash
#
# Environment setup script for building modern Linux for C.H.I.P. with Yocto
#

if [ "$BASH_SOURCE" = "$0" ]; then
    echo "Error: This script must be sourced, not executed directly."
    echo "Usage: source setup-env.sh [build-dir]"
    exit 1
fi

LAYER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$LAYER_DIR/.." && pwd)"
BUILD_DIR="${1:-build-chip}"
YOCTO_BRANCH="${YOCTO_BRANCH:-scarthgap}"

echo "========================================================"
echo " Setting up Yocto environment for Next Thing Co. C.H.I.P."
echo " Target Yocto Release: $YOCTO_BRANCH (LTS)"
echo "========================================================"

# Check if Poky is present, clone if missing
if [ ! -d "$PARENT_DIR/poky" ]; then
    echo "Poky not found in $PARENT_DIR/poky. Cloning $YOCTO_BRANCH branch..."
    git clone --branch "$YOCTO_BRANCH" https://git.yoctoproject.org/git/poky "$PARENT_DIR/poky"
fi

cd "$PARENT_DIR" || return 1

# Initialize Yocto build environment
source "$PARENT_DIR/poky/oe-init-build-env" "$BUILD_DIR"

# Add meta-chip layer if not already added
if ! bitbake-layers show-layers 2>/dev/null | grep -q "meta-chip"; then
    echo "Adding meta-chip layer to bblayers.conf..."
    bitbake-layers add-layer "$LAYER_DIR"
fi

# Configure local.conf for C.H.I.P. machine if not already configured
if ! grep -q 'MACHINE ??= "chip"' conf/local.conf 2>/dev/null; then
    echo "Setting MACHINE = \"chip\" in conf/local.conf..."
    sed -i 's/^MACHINE ??=.*/MACHINE ??= "chip"/' conf/local.conf
fi

echo ""
echo "========================================================"
echo " Yocto build environment is ready for C.H.I.P.!"
echo " Machine: chip (Allwinner R8 Cortex-A8)"
echo " Kernel:  Mainline Linux 6.6 LTS"
echo " U-Boot:  Mainline U-Boot 2024.01"
echo ""
echo " Recommended build targets:"
echo "   bitbake chip-image-minimal    (Minimal, fast-booting console image)"
echo "   bitbake chip-image-base       (Full image with WiFi, BT, SSH, and debug tools)"
echo "========================================================"
