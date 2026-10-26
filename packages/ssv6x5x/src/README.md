# SSV6256P (SSV6X5X) WiFi Driver for Linux Kernel 6.x+

This repository contains my port of the **SV6256P / SSV6X5X SDIO Wi‑Fi driver** from legacy Linux 4.4 to **Linux 6.x and above**.  
The driver now builds and runs on modern kernels, with updated mac80211/cfg80211 integration.

[![License](https://img.shields.io/badge/License-Dual%20BSD%2FGPL-blue.svg)](LICENSE)
[![Kernel](https://img.shields.io/badge/Kernel-6.0+-green.svg)](https://kernel.org/)
[![Architecture](https://img.shields.io/badge/Arch-ARM64-orange.svg)](https://www.kernel.org/doc/html/latest/arm64/index.html)

## 📖 Background

The SSV6256P is a dual-band WiFi chipset from iComm Semiconductor, commonly found in low-cost TV boxes, embedded Linux devices, and IoT applications. The original driver was designed for Linux kernel 4.4, but modern Linux distributions use kernel 6.x which introduced significant changes to the mac80211 wireless stack.

This repository contains a fully functional port of the SSV6256P driver to Linux kernel 6.x+, with all necessary API adaptations and bug fixes.

### Tested Hardware

- **SoC**: Allwinner H616 (ARM Cortex-A53)
- **Board**: X96 Q TV Box
- **Interface**: SDIO
- **Kernel**: Armbian_25.05.0_linux_6.12.11-edge-sunxi64

## ✅ Kernel Compatibility

| Kernel Version | Status | Notes |
|---------------|--------|-------|
| 6.12.x  | ✅ Tested    | Tested on 6.12.11 |
| 6.13.x+ | ✅ Tested    | Tested on 6.18.23 |
| 7.0.x+  | ✅ Expected  | Should work (API-compatible) |
| 6.6 LTS | ✅ Tested    | Tested on 6.6.44 |
| 5.x | ❌ Not supported | Use original driver |
| 4.x | ❌ Not supported | Use original driver |

## 📦 Prerequisites

### Required Packages (Debian/Ubuntu)

```bash
sudo apt-get update
sudo apt-get install -y build-essential linux-headers-$(uname -r) git
```

### Required Packages (Arch Linux)

```bash
sudo pacman -S base-devel linux-headers
```

### Required Packages (Fedora/RHEL)

```bash
sudo dnf install kernel-devel kernel-headers gcc make
```

## 🔨 Installation

### Method 1: DKMS (Recommended)

DKMS automatically rebuilds the driver when you upgrade the kernel.

```bash
# Install prerequisites
sudo apt-get install -y dkms build-essential linux-headers-$(uname -r) git

# Clone and install
git clone https://github.com/cdhigh/armbian_sv6256p.git
cd armbian_sv6256p
sudo bash ./install-dkms.sh
sudo modprobe ssv6x5x
```

### Method 2: Manual Compilation

```bash
# Install prerequisites
sudo apt-get install -y build-essential linux-headers-$(uname -r) git

# Clone and build
git clone https://github.com/cdhigh/armbian_sv6256p.git
cd armbian_sv6256p
make ARCH=arm64 KSRC=/lib/modules/$(uname -r)/build
ls -lh ssv6x5x.ko
```

#### Manual Installation

```bash
sudo cp ./ssv6x5x-wifi.cfg /lib/firmware/
sudo cp ./ssv6x5x-sw.bin /lib/firmware/
sudo mkdir -p /lib/modules/$(uname -r)/kernel/drivers/net/wireless/ssv6256p/
sudo cp ./ssv6x5x.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/ssv6256p/
sudo depmod -a
sudo modprobe ssv6x5x
```

### Method 3: Armbian Extension

For building custom Armbian images with SSV6X5X support:

```bash
# Copy the extension to your Armbian build environment
cp -r armbian/extensions/ssv6x5x.sh /path/to/armbian-build/userpatches/extensions/

# Build with the extension enabled
./compile.sh ENABLE_EXTENSIONS="ssv6x5x"
```

## 🚀 Usage

### Verify Driver Loading

Check kernel log for successful initialization:

```bash
dmesg | grep -i ssv
```

### Identify Network Interface

```bash
ip link show
# or
iw dev
```

Look for `wlan0` or similar interface.

### Scan for Networks

```bash
sudo iw dev wlan0 scan | grep SSID
```

### Connect to WiFi

```bash
nmcli device wifi connect "YourSSID" password "YourPassword"
or
nmtui
```

## 📦 DKMS Management

```bash
# Check driver status
dkms status ssv6x5x

# Rebuild for current kernel
sudo dkms build ssv6x5x/6.0.0
sudo dkms install ssv6x5x/6.0.0

# Uninstall
sudo dkms remove ssv6x5x/6.0.0 --all
```

# Credits
* Vendor driver sources
* Linux mac80211 maintainers for API references
* Community help on porting legacy Wi‑Fi drivers

