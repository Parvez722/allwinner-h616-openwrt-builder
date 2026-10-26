# Allwinner H616 Firmware Builder (OpenWrt, ImmortalWrt, KWRT & Armbian)

[![Build OpenWrt / ImmortalWrt](https://github.com/Parvez722/allwinner-h616-openwrt-builder/actions/workflows/build-allwinner-h616.yml/badge.svg)](https://github.com/Parvez722/allwinner-h616-openwrt-builder/actions/workflows/build-allwinner-h616.yml)
[![Build Armbian](https://github.com/Parvez722/allwinner-h616-openwrt-builder/actions/workflows/build-armbian.yml/badge.svg)](https://github.com/Parvez722/allwinner-h616-openwrt-builder/actions/workflows/build-armbian.yml)

Automated GitHub Actions builder for Allwinner H616 / H313 TV Boxes (specifically **TX9 Pro**, **X96Q DDR3L**, and compatible boards based on `H616/H313mini84_V3.0`).

---

## 📦 Supported Builds

| Platform | Distributions / Releases | Package Manager / Utilities | Output Formats |
| :--- | :--- | :--- | :--- |
| **OpenWrt / ImmortalWrt** | `ImmortalWrt`, `OpenWrt`, `KWRT` (LEDE) | `apk` (v25 / master) or `opkg` (v24.10) | `.img.gz` (ext4 & squashfs) |
| **Armbian Linux** | Debian 12 Bookworm, Ubuntu Noble | Full CLI (`nmcli`, `nmtui`, `ethtool`, etc.) | `.img.xz` |

---

## 🚀 Key Hardware Support & Integrated Fixes

### 1. 🌐 AC300 RMII Ethernet (100 Mbps)
- **Problem in generic images:** The AC300 internal PHY on Allwinner EMAC1 (`0x5030000`) fails probe or suffers from continuous `NETDEV WATCHDOG: transmit queue 0 timed out` errors every 5 seconds because the RMII clock enable bits (`0x50000`) in system control register `0x34` are not configured.
- **Integrated Fix:** Patched `dwmac-sun8i` driver with H616 EMAC1 `syscon` clock support and regulator mappings in the device tree, giving 100 Mbps Full Duplex wire speed with zero packet loss.

### 2. 📶 iComm SV6256P / SSV6006C Wi-Fi
- **Problem in generic images:** Generic Linux kernels and distributions lack drivers for the iComm SV6256P SDIO Wi-Fi (`7c:94:9f:f7:xx:xx`). Compiling against modern OpenWrt mac80211 backports causes kernel structure offsets (`-12 -ENOMEM` probe errors).
- **Integrated Fix:** Pre-patched, backport-aligned `ssv6x5x` kernel module and firmware supporting dual-band 2.4 GHz and 5 GHz AP modes.

### 3. ⚙️ Plug-and-Play Defaults
- **OpenWrt / ImmortalWrt:**
  - Default IP: `192.168.1.99` (prevents default IP conflicts with home routers at `192.168.1.1`)
  - Subnet: `255.255.255.0`, Gateway: `192.168.1.1`
  - Wi-Fi AP: Automatically enabled on first boot (`TX9Pro-5G`) without requiring manual serial/SSH setup.
- **Armbian:**
  - Default User: `root`
  - Default Password: `1234` (Non-expiring; bypasses first-run wizard so serial and headless logins work immediately)
  - Pre-installed Tools: `network-manager` (**`nmcli`**, **`nmtui`**), `wireless-tools` (`iwconfig`), `wpasupplicant`, `ethtool`, `curl`, `wget`, `htop`, `nano`, `net-tools` (`ifconfig`), `iperf3`.

---

## 🛠️ How to Trigger Builds in GitHub Actions

1. Go to the **Actions** tab of this repository.
2. Select your desired workflow in the left sidebar:
   - **Build OpenWrt / ImmortalWrt for Allwinner H616**: Choose distribution (`ImmortalWrt`, `OpenWrt`, `KWRT`) and version (`master v25 apk` or `24.10 v24 opkg`).
   - **Build Armbian for Allwinner H616**: Choose kernel branch (`edge` 6.12 or `current` 6.6) and release (`bookworm` or `noble`).
3. Click **Run workflow**.
4. The workflow will compile the image and automatically publish it to **GitHub Releases** and workflow artifacts.

---

## 💾 Flashing to MicroSD / TF Card

1. Download the generated image from GitHub Releases:
   - OpenWrt: `*.img.gz`
   - Armbian: `*.img.xz`
2. Flash using **BalenaEtcher**, **Rufus**, or `dd`:
   ```bash
   # For OpenWrt:
   gzip -dc ImmortalWrt-TX9Pro-H616-apk-ext4-sdcard.img.gz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
   
   # For Armbian:
   xz -dc Armbian-TX9Pro-H616-bookworm-edge.img.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
   ```
3. Insert the card into your TV box TF slot and power on.

---

## 🔑 Default Credentials & Access

| System | Web / Port | User | Password | Details |
| :--- | :--- | :--- | :--- | :--- |
| **OpenWrt / ImmortalWrt** | `http://192.168.1.99` | `root` | *(none)* | LuCI Web & SSH |
| **Armbian Linux** | `ssh root@<ip>` | `root` | `1234` | Direct login enabled |
| **Serial TTL** | `115200 8N1` | `root` | *(as above)* | UART0 on board header |

---

## 📁 Repository Structure

```
├── .github/workflows/
│   ├── build-allwinner-h616.yml    # OpenWrt / ImmortalWrt / KWRT automated workflow
│   └── build-armbian.yml           # Armbian Linux automated workflow
├── armbian/
│   └── userpatches/
│       ├── customize-image.sh      # Installs nmcli, nmtui, wifi & sets credentials
│       ├── kernel/                 # EMAC1 RMII syscon clock patch
│       └── overlay/                # Fixed DTB, ssv6x5x wifi deb, dwmac-sun8i.ko
├── configs/
│   ├── tx9pro_h616.config          # Target definition and core packages
│   └── immortalwrt-v25-h616.config # Full verified working configuration
├── packages/
│   └── ssv6x5x/                    # iComm SV6256P Wi-Fi kernel driver package
├── patches/
│   └── sun50i-h313-x96-q-v5.1.dts  # Verified device tree with Ethernet & PMIC fixes
└── scripts/
    └── init-build.sh               # OpenWrt injection hook
```

---

## 📄 License
OpenWrt, ImmortalWrt, and Armbian are licensed under GPL-2.0.
