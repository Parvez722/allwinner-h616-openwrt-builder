# Allwinner H616 OpenWrt / ImmortalWrt / KWRT Automated Builder

[![Build OpenWrt / ImmortalWrt for Allwinner H616](https://github.com/OWNER/REPO/actions/workflows/build-allwinner-h616.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/build-allwinner-h616.yml)

Automated GitHub Actions builder for Allwinner H616 / H313 TV Boxes (specifically **TX9 Pro**, **X96Q DDR3L**, and compatible boards based on `H616/H313mini84_V3.0`).

This builder automates compilation of:
- **ImmortalWrt** (v25 `master` with `apk` package manager, and `openwrt-24.10` with `opkg`)
- **Official OpenWrt** (`main` with `apk`, and `openwrt-24.10` with `opkg`)
- **KWRT (Lean LEDE)** (`master` with `opkg`)

---

## 🚀 Key Hardware Support & Integrated Fixes

### 1. 🌐 AC300 RMII Ethernet (100 Mbps)
- **Problem in generic images:** The AC300 internal PHY on Allwinner EMAC1 (`0x5030000`) fails probe with timeout `-110` on vanilla kernels because the reset routine attempts to communicate before the PHY and Port A clock/regulators are fully powered.
- **Integrated Fix:** Custom device tree binding Port A regulators and an updated driver sequence allowing proper MDIO auto-negotiation and link establishment (100 Mbps Full Duplex).

### 2. 📶 iComm SV6256P / SSV6006C Wi-Fi
- **Problem in generic images:** Generic Linux kernels and OpenWrt distributions lack out-of-tree drivers for iComm SV6256P SDIO Wi-Fi (`7c:94:9f:f7:xx:xx`). Compiling against modern OpenWrt mac80211 backports causes kernel structure offsets (`-12 -ENOMEM` probe errors).
- **Integrated Fix:** Pre-patched, backport-aligned `kmod-ssv6x5x` package that seamlessly builds under both `apk` (v25) and `opkg` (v24) environments. Dual-band 2.4 GHz and 5 GHz AP modes supported.

### 3. ⚙️ Plug-and-Play Network Defaults
- **Default IP:** `192.168.1.99` (prevents default IP conflicts with home routers at `192.168.1.1`)
- **Default Subnet:** `255.255.255.0`
- **Default Gateway:** `192.168.1.1`
- **Default DNS:** `1.1.1.1 8.8.8.8`
- **Wi-Fi AP:** Automatically enabled on first boot with SSID `TX9Pro-5G` (or `ImmortalWrt`) without requiring manual serial/SSH setup.

---

## 🛠️ How to Trigger a Build in GitHub Actions

1. Fork or clone this repository to your GitHub account.
2. Go to the **Actions** tab.
3. In the left sidebar, click **Build OpenWrt / ImmortalWrt for Allwinner H616 (TX9 Pro / X96Q)**.
4. Click **Run workflow**:
   - **Firmware Distribution:** Select `ImmortalWrt`, `OpenWrt`, or `KWRT`.
   - **Branch / Release Version:**
     - `master (v25 apk)`: Latest bleeding-edge OpenWrt/ImmortalWrt with alpine-style `apk` package manager.
     - `openwrt-24.10 (v24 opkg)`: Stable branch with traditional `opkg` package manager.
   - **Publish as GitHub Release:** Check to automatically tag and upload flashable `.img.gz` images and checksums to GitHub Releases.
5. Click the green **Run workflow** button.

---

## 💾 Flashing to MicroSD / TF Card

1. Download the generated SD card image from the GitHub Release or Actions artifacts:
   - `*-ext4-sdcard.img.gz` (Recommended for easy rootfs expansion)
   - `*-squashfs-sdcard.img.gz` (Read-only rootfs with factory reset support)
2. Extract the `.gz` file (or flash directly with BalenaEtcher).
3. Use **BalenaEtcher**, **Rufus**, or `dd` to write the image to your MicroSD card (Class 10 / U1 or higher recommended):
   ```bash
   gzip -dc ImmortalWrt-TX9Pro-H616-apk-ext4-sdcard.img.gz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
   ```
4. Insert the card into the TV box TF slot and power it on.

---

## 🔑 Accessing the System

| Interface | Address / Details | Credentials |
| :--- | :--- | :--- |
| **LuCI Web Interface** | `http://192.168.1.99` | User: `root`, Password: *(none)* |
| **SSH Terminal** | `ssh root@192.168.1.99` | User: `root`, Password: *(none)* |
| **Wi-Fi Access Point** | `TX9Pro-5G` / `ImmortalWrt` | Open / No password by default |
| **Baud Rate (Serial TTL)** | `115200 8N1` (TX, RX, GND) | Direct root shell |

---

## 📁 Repository Structure

```
├── .github/workflows/
│   └── build-allwinner-h616.yml    # GitHub Actions workflow
├── configs/
│   ├── tx9pro_h616.config          # Target definition and core packages
│   └── immortalwrt-v25-h616.config # Full verified working configuration
├── packages/
│   └── ssv6x5x/                    # iComm SV6256P Wi-Fi kernel driver package
├── patches/
│   └── sun50i-h313-x96-q-v5.1.dts  # Verified device tree with Ethernet & PMIC fixes
└── scripts/
    └── init-build.sh               # Injection hook for feeds, DTB, and uci-defaults
```

---

## 📄 License
OpenWrt and ImmortalWrt are licensed under the GPL-2.0 License. All patches and custom packages in this repository are distributed under GPL-2.0 or compatible licenses.
