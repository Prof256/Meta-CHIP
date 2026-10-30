# Meta-CHIP: Yocto BSP Layer for Next Thing Co. C.H.I.P.

`meta-chip` is a modern **Yocto Project / OpenEmbedded Board Support Package (BSP) layer** for the **Next Thing Co. C.H.I.P.** ($9 single-board computer).

It replaces legacy, unmaintained 3.4/4.4 vendor kernels with modern upstream software:
* **Yocto Releases:** **Scarthgap (5.0 LTS)** / **Kirkstone (4.0 LTS)**
* **Linux Kernel:** **Mainline Linux 6.6 LTS** (`linux-chip`)
* **Bootloader:** **Mainline Das U-Boot 2024.01** (`u-boot-chip`)
* **Hardware Support:**
  * Allwinner R8 SoC (ARM Cortex-A8 @ 1GHz with NEON and VFPv3-D32)
  * X-Powers AXP209 PMIC (power rails, battery charging, power-off)
  * Realtek RTL8723BS Wi-Fi (802.11b/g/n) and Bluetooth 4.0 LE
  * USB 2.0 Type-A Host port
  * Micro-USB OTG port (power in, serial gadget, Ethernet gadget, FEL mode)
  * Dual storage support: **USB flash drive (recommended)** and **Onboard Raw NAND (UBIFS)**

---

## Repository Structure

```text
Meta-CHIP/
├── conf/
│   ├── layer.conf                       # Yocto layer definition (scarthgap/kirkstone compat)
│   ├── machine/
│   │   └── chip.conf                    # Next Thing Co. C.H.I.P. machine configuration
│   └── templates/default/               # Template bblayers.conf and local.conf
│       ├── bblayers.conf.sample
│       └── local.conf.sample
├── recipes-bsp/
│   └── u-boot/
│       ├── files/
│       │   └── boot.cmd                 # Distro boot script (scans USB first, then NAND UBI)
│       └── u-boot-chip_2024.01.bb       # Mainline U-Boot recipe
├── recipes-kernel/
│   └── linux/
│       ├── linux-chip/
│       │   └── defconfig                # Tailored minimal kernel config for Allwinner R8
│       └── linux-chip_6.6.bb            # Mainline Linux 6.6 LTS recipe
├── recipes-core/
│   └── images/
│       ├── chip-image-minimal.bb        # Lightweight console image (~30 MB)
│       └── chip-image-base.bb           # Image with WiFi, BT, SSH, and diagnostic tools
├── scripts/
│   ├── flash-chip.sh                    # Host helper for FEL-mode testing and RAM booting
│   └── create-usb-boot.sh               # Format and install rootfs onto a USB flash drive
├── setup-env.sh                         # One-click environment initialization script
└── README.md
```

---

## 1. Host Setup & Prerequisites

Yocto requires a Linux host. On Windows 10/11, you can build inside **WSL2 (Ubuntu 22.04 LTS or 24.04 LTS)** or a Linux VM.

> **Tip for Windows WSL2 users:** Perform your Yocto build inside the Linux virtual filesystem (e.g., `~/yocto/`) rather than `/mnt/c/`, as native ext4 inside WSL2 is 5–10x faster for BitBake and build output.

### Install Host Dependencies (Ubuntu / Debian):
```bash
sudo apt update
# Install Packages for Yocto
sudo apt install build-essential chrpath cpio debianutils diffstat file gawk \
     gcc git iputils-ping libacl1 libcrypt-dev locales python3 python3-git \ 
     python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo \ 
     unzip wget xz-utils zstd
#Install Packages for CHIP
sudo apt install -y libegl-mesa0 libsdl1.2-dev pylint lz4 sunxi-tools parted
```

---

## 2. Quickstart: Building with Yocto

### Step 1: Clone Poky and Meta-CHIP
```bash
# Create a workspace directory
mkdir -p ~/yocto-chip && cd ~/yocto-chip

# Clone Poky (Yocto Scarthgap LTS branch)
git clone --branch scarthgap https://git.yoctoproject.org/git/poky

# Clone Meta-CHIP
# Replace the URL below if you are using a fork or a local checkout.
git clone https://github.com/Prof256/Meta-CHIP.git meta-chip
```

### Step 2: Initialize Build Environment
Using the bundled setup script:
```bash
source meta-chip/setup-env.sh
```
Or manually:
```bash
source poky/oe-init-build-env build-chip
bitbake-layers add-layer ../meta-chip
```
Ensure `conf/local.conf` contains:
```bitbake
MACHINE = "chip"
```

### Step 3: Build an Image
Build the minimal console image:
```bash
bitbake chip-image-minimal
```
Or build the full image with WiFi, Bluetooth, and SSH:
```bash
bitbake chip-image-base
```

The build artifacts will be produced in:
`build-chip/tmp/deploy/images/chip/`:
* `zImage`: Modern Linux kernel
* `sun5i-r8-chip.dtb`: Device tree blob
* `u-boot-sunxi-with-spl.bin`: Complete U-Boot binary with SPL
* `boot.scr`: U-Boot distro boot script
* `chip-image-minimal-chip.rootfs.tar.gz`: Root filesystem archive (for USB)
* `chip-image-minimal-chip.rootfs.ubi`: UBIFS image (for onboard NAND)

---

## 3. Booting & Flashing Options

### Option A: USB Flash Drive Boot (Recommended)
Because the C.H.I.P.'s onboard NAND can suffer from bad blocks and paired-page MLC wear, running Linux from a standard USB flash drive plugged into the USB-A port is the fastest, most reliable method for getting a modern system up and running.

1. Insert a USB flash drive into your PC.
2. Use the provided script to partition and extract the root filesystem:
   ```bash
   sudo ./meta-chip/scripts/create-usb-boot.sh /dev/sdX build-chip/tmp/deploy/images/chip/chip-image-base-chip.rootfs.tar.gz
   ```
3. Copy `/boot` files (`zImage`, `sun5i-r8-chip.dtb`, and `boot.scr`) to `/boot` on the USB drive.
4. Plug the USB drive into the C.H.I.P.'s USB port and power on. U-Boot will automatically detect the USB drive and boot into modern Linux!

---

### Option B: Test-Booting Over USB with FEL Mode (No Flashing Required)
You can boot a modern kernel directly into RAM over Micro-USB without touching the onboard NAND:

1. Connect a jumper wire or paperclip between **FEL (pin 7)** on header **U14** and **GND (pin 1 or 2)**.
2. Connect the Micro-USB cable to your PC.
3. Verify connection:
   ```bash
   sunxi-fel ver
   # Output should confirm: AWUSBFEX soc=00001625(A13/R8) 00000001 ver=0001 ...
   ```
4. Run the helper script:
   ```bash
   ./meta-chip/scripts/flash-chip.sh
   # Select option 1 (RAM Boot)
   ```
5. Remove the FEL jumper after boot starts.

---

### Option C: Onboard Raw NAND (UBIFS)
To flash the onboard NAND:
* Page size: `16384` bytes (16 KB)
* Physical Erase Block (PEB): `2097152` bytes (2 MB)
* Logical Erase Block (LEB): `2064384` bytes
The generated `*.rootfs.ubi` file can be flashed to the MTD partition labeled `rootfs` using U-Boot's `nand write` or `ubifsmount`.

---

## 4. Hardware Pinouts & Serial Console

### Serial Debug Console (UART0)
To view boot logs and log into the console, connect a 3.3V USB-to-UART adapter to header **U13**:
* **U13 Pin 1:** `GND` -> UART Adapter GND
* **U13 Pin 3:** `UART1-TX` (ttyS0 TX) -> UART Adapter RX
* **U13 Pin 5:** `UART1-RX` (ttyS0 RX) -> UART Adapter TX
* **Baud Rate:** `115200 8N1`

### FEL Mode Header (U14)
* **U14 Pin 1 or 2:** `GND`
* **U14 Pin 7:** `FEL`
Bridge Pin 7 to GND before powering on to put the Allwinner R8 SoC into USB FEL mode.

---

## License
MIT License. See individual recipes for upstream software licenses (GPLv2 for Linux and U-Boot).
