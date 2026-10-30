# Meta-CHIP: Yocto BSP Layer for Next Thing Co. C.H.I.P.

`meta-chip` is a beginner-friendly Yocto Project / OpenEmbedded Board Support Package (BSP) layer for the **Next Thing Co. C.H.I.P.** single-board computer.

This layer replaces old vendor kernels with modern upstream software and is designed to help you build a usable Linux system for the C.H.I.P. using current Yocto tools.

It includes:
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

## What this repo contains

```text
Meta-CHIP/
├── conf/
│   ├── layer.conf                       # Yocto layer definition
│   ├── machine/
│   │   └── chip.conf                    # C.H.I.P. machine configuration
│   └── templates/default/
│       ├── bblayers.conf.sample
│       └── local.conf.sample
├── recipes-bsp/
│   └── u-boot/
│       ├── files/
│       │   └── boot.cmd                 # U-Boot boot script
│       └── u-boot-chip_2024.01.bb
├── recipes-kernel/
│   └── linux/
│       ├── linux-chip/
│       │   └── defconfig
│       └── linux-chip_6.6.bb
├── recipes-core/
│   └── images/
│       ├── chip-image-minimal.bb
│       └── chip-image-base.bb
├── scripts/
│   ├── flash-chip.sh
│   └── create-usb-boot.sh
├── setup-env.sh                         # Helper script to initialize the build
├── README.md
└── LICENSE
```

---

## Before you start

This project is for a Linux build host. If you are on Windows, use **WSL2 (Ubuntu 22.04 or 24.04)** instead of building directly on Windows.

Important:
* Use a real Linux environment for Yocto builds.
* Keep your build directory on the Linux filesystem, not under `/mnt/c` if possible.
* Make sure Git is installed and working.

> Tip: On WSL2, keeping the work under something like `~/yocto-chip` is much faster and more reliable than building in `/mnt/c`.

### Install dependencies on Ubuntu / Debian

```bash
sudo apt-get update
sudo apt-get install -y gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
    iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
    pylint zstd liblz4-tool sunxi-tools parted
```

---

## Quick start: build the C.H.I.P. image

### Step 1: Create a workspace

```bash
mkdir -p ~/yocto-chip
cd ~/yocto-chip
```

### Step 2: Clone Yocto Poky and this layer

Use the HTTPS URL for Yocto, not the older git protocol form.

```bash
# Clone the Yocto project
git clone --branch scarthgap https://git.yoctoproject.org/git/poky

# Clone this BSP layer
git clone https://github.com/Prof256/Meta-CHIP.git meta-chip
```

If you are using a fork, replace the GitHub URL with your fork URL.

### Step 3: Initialize the build environment

From inside your workspace:

```bash
cd ~/yocto-chip
source meta-chip/setup-env.sh
```

This script checks whether Poky is present, clones it if needed, initializes the build directory, adds the `meta-chip` layer, and sets `MACHINE = "chip"` in the local configuration.

### Step 4: Build an image

Once the environment is ready, build one of the included images:

```bash
bitbake chip-image-minimal
```

or

```bash
bitbake chip-image-base
```

The minimal image is the fastest and simplest starting point.
The base image adds WiFi, Bluetooth, SSH, and debugging tools.

### Step 5: Check your output files

After a successful build, the generated files are usually in:

```text
build-chip/tmp/deploy/images/chip/
```

Common output files include:
* `zImage` - Linux kernel
* `sun5i-r8-chip.dtb` - device tree blob
* `u-boot-sunxi-with-spl.bin` - U-Boot image
* `boot.scr` - U-Boot boot script
* `chip-image-minimal-chip.rootfs.tar.gz` - USB root filesystem archive
* `chip-image-minimal-chip.rootfs.ubi` - UBIFS image for NAND

---

## Recommended usage

### Option A: Boot from USB flash drive (recommended)
This is the easiest and most reliable method for a first-time setup.

```bash
sudo ./meta-chip/scripts/create-usb-boot.sh /dev/sdX build-chip/tmp/deploy/images/chip/chip-image-base-chip.rootfs.tar.gz
```

Then copy the boot files (`zImage`, `sun5i-r8-chip.dtb`, `boot.scr`) to the USB drive's `/boot` directory and boot the C.H.I.P. from the USB port.

### Option B: RAM boot using FEL mode
This method lets you test the system without flashing the internal NAND.

1. Short **FEL** to **GND** on header **U14**.
2. Connect the board by USB.
3. Run:
   ```bash
   sunxi-fel ver
   ```
4. Then:
   ```bash
   ./meta-chip/scripts/flash-chip.sh
   ```
5. Choose the RAM boot option.

### Option C: Flash to onboard NAND
This is for advanced users who want to write the system to the internal NAND flash.

---

## Serial console and hardware notes

### Serial debug console
Connect a USB-to-UART adapter to header **U13**:
* **U13 Pin 1:** `GND`
* **U13 Pin 3:** `UART1-TX` -> adapter `RX`
* **U13 Pin 5:** `UART1-RX` -> adapter `TX`
* **Baud Rate:** `115200 8N1`

### FEL mode header
* **U14 Pin 1 or 2:** `GND`
* **U14 Pin 7:** `FEL`

Bridge pin 7 to GND before power-on to enter FEL mode.

---

## Common beginner problems

### `git: protocol 'git' is not supported`
This usually means you used the old git protocol URL.
Use:

```bash
git clone --branch scarthgap https://git.yoctoproject.org/git/poky
```

### `bitbake: command not found`
This usually means you did not source the environment correctly.
Run:

```bash
source meta-chip/setup-env.sh
```

### `MACHINE` is not set
Ensure your `conf/local.conf` contains:

```bitbake
MACHINE = "chip"
```

### Build directory is in the wrong place
If you are on Windows, avoid building inside `/mnt/c`. Use WSL2 and keep your workspace under `~/yocto-chip`.

---

## License

MIT License. See upstream recipes for their respective software licenses (for example, Linux and U-Boot are GPLv2-based).

---

## Need help?

If you are new to Yocto, start with the `chip-image-minimal` target. It is the easiest path to a working build and reduces the number of variables you need to debug during your first attempt.
