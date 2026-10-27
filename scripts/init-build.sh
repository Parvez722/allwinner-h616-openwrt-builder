#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${1:-.}"

echo "=== [1/8] Injecting iComm SV6256P / SSV6X5X Wi-Fi Package ==="
mkdir -p "${BUILD_DIR}/package/kernel"
cp -rf "${REPO_ROOT}/packages/ssv6x5x" "${BUILD_DIR}/package/kernel/"

echo "=== [2/8] Ensuring Argon Theme & Config Packages Available ==="
if [ ! -d "${BUILD_DIR}/package/luci-theme-argon" ] && [ ! -d "${BUILD_DIR}/feeds/luci/themes/luci-theme-argon" ]; then
    echo "Cloning luci-theme-argon & config into package/..."
    git clone --depth 1 -b master https://github.com/jerrykuku/luci-theme-argon.git "${BUILD_DIR}/package/luci-theme-argon" 2>/dev/null || true
    git clone --depth 1 -b master https://github.com/jerrykuku/luci-app-argon-config.git "${BUILD_DIR}/package/luci-app-argon-config" 2>/dev/null || true
fi

echo "=== [3/8] Injecting Verified TX9 Pro / X96Q DDR3L Device Tree & Kernel Patches ==="
DTS_DIR="${BUILD_DIR}/target/linux/sunxi/files/arch/arm64/boot/dts/allwinner"
mkdir -p "${DTS_DIR}"
cp -vf "${REPO_ROOT}/patches/sun50i-h313-x96-q-v5.1.dts" "${DTS_DIR}/sun50i-h313-x96-q-v5.1.dts"

for patch_dir in "${BUILD_DIR}/target/linux/sunxi/patches-6.12" "${BUILD_DIR}/target/linux/sunxi/patches-6.6"; do
    if [ -d "${patch_dir}" ]; then
        echo "Injecting Ethernet & DTB patches into ${patch_dir}..."
        cp -vf "${REPO_ROOT}/patches/9785-drv-net-stmmac-dwmac-sun8i-second-EMAC-clock-register.patch" "${patch_dir}/"
        cp -vf "${REPO_ROOT}/patches/9958-arm64-dts-allwinner-h313-add-x96q-v5.1-TVbox.patch" "${patch_dir}/"
    fi
done

echo "=== [4/8] Injecting U-Boot Patches for X96Q / TX9 Pro DDR3 ==="
python3 -m pip install --break-system-packages "setuptools<70" 2>/dev/null || python3 -m pip install "setuptools<70" 2>/dev/null || true
UBOOT_PATCH_DIR="${BUILD_DIR}/package/boot/uboot-sunxi/patches"
mkdir -p "${UBOOT_PATCH_DIR}"
for p in "${REPO_ROOT}/patches"/163* "${REPO_ROOT}/patches"/290* "${REPO_ROOT}/patches"/300* "${REPO_ROOT}/patches"/301*; do
    if [ -f "$p" ]; then
        cp -vf "$p" "${UBOOT_PATCH_DIR}/"
    fi
done

echo "=== [5/8] Registering U-Boot/x96q in package/boot/uboot-sunxi/Makefile ==="
UBOOT_MK="${BUILD_DIR}/package/boot/uboot-sunxi/Makefile"
if [ -f "${UBOOT_MK}" ]; then
    python3 - << PYEOF
mk = "${UBOOT_MK}"
with open(mk, 'r') as f:
    c = f.read()
if "define U-Boot/x96q" not in c:
    block = """
define U-Boot/x96q
  BUILD_SUBTARGET:=cortexa53
  NAME:=TX9 Pro / X96Q DDR3
  BUILD_DEVICES:=x96q
  UBOOT_CONFIG:=x96_q_ddr3_v5.1
  DEPENDS:=+PACKAGE_u-boot-x96q:trusted-firmware-a-sunxi-h616
  UENV:=h616
  ATF:=h616
endef

UBOOT_TARGETS += x96q
"""
    target = "\$(eval \$(call BuildPackage/U-Boot))"
    if target in c:
        c = c.replace(target, block + "\\n" + target)
        with open(mk, 'w') as f:
            f.write(c)
        print("Successfully registered U-Boot/x96q before BuildPackage/U-Boot")
    else:
        print("Target BuildPackage/U-Boot not found")
else:
    print("U-Boot/x96q already registered")
PYEOF
fi

echo "=== [6/8] Registering Device/x96q in target/linux/sunxi/image/cortexa53.mk ==="
MK_FILE="${BUILD_DIR}/target/linux/sunxi/image/cortexa53.mk"
if [ -f "${MK_FILE}" ]; then
    if ! grep -q "define Device/x96q" "${MK_FILE}"; then
        cat << 'EOF' >> "${MK_FILE}"

define Device/x96q
  DEVICE_VENDOR := Allwinner
  DEVICE_MODEL := X96Q / TX9 Pro DDR3
  SUNXI_DTS := allwinner/sun50i-h313-x96-q-v5.1
  $(Device/sun50i-h616)
endef
TARGET_DEVICES += x96q
EOF
        echo "Successfully registered Device/x96q in cortexa53.mk"
    else
        echo "Device/x96q already registered in cortexa53.mk"
    fi
fi

echo "=== [7/8] Injecting Out-Of-The-Box Network (eth0 as WAN, Open Ports, Argon Theme) ==="
UCI_DIR="${BUILD_DIR}/package/base-files/files/etc/uci-defaults"
mkdir -p "${UCI_DIR}"
cat << 'EOF' > "${UCI_DIR}/99-tx9pro-custom-defaults"
#!/bin/sh

# 1. Configure built-in eth0 as WAN (DHCP Client from upstream network)
uci -q delete network.lan.device
uci -q delete network.@device[0].ports
uci set network.wan=interface
uci set network.wan.device='eth0'
uci set network.wan.proto='dhcp'

# 2. Configure LAN (used for Wi-Fi AP, USB Ethernet adapters, USB Tethering)
# Set to 192.168.8.1 to prevent IP conflict with main router (192.168.1.1)
uci set network.lan.proto='static'
uci set network.lan.ipaddr='192.168.8.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

# 3. Allow full access from WAN & LAN for all ports (SSH, LuCI WebUI, etc.)
uci set firewall.@zone[1].input='ACCEPT'
uci set firewall.@zone[1].forward='ACCEPT'
uci set firewall.@zone[0].input='ACCEPT'
uci set firewall.@zone[0].forward='ACCEPT'

uci add firewall rule
uci set firewall.@rule[-1].name='Allow-LuCI-WAN'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].dest_port='80 443'
uci set firewall.@rule[-1].target='ACCEPT'

uci add firewall rule
uci set firewall.@rule[-1].name='Allow-SSH-WAN'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].dest_port='22'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall

# 4. Ensure uhttpd listens on all interfaces (0.0.0.0)
uci set uhttpd.main.listen_http='0.0.0.0:80'
uci -q add_list uhttpd.main.listen_http='[::]:80'
uci -q set uhttpd.main.listen_https='0.0.0.0:443'
uci -q add_list uhttpd.main.listen_https='[::]:443'
uci commit uhttpd

# 5. Enable SSH root password & gateway ports
uci set dropbear.@dropbear[0].RootPasswordAuth='on' 2>/dev/null || true
uci set dropbear.@dropbear[0].PasswordAuth='on' 2>/dev/null || true
uci set dropbear.@dropbear[0].GatewayPorts='on' 2>/dev/null || true
uci commit dropbear

# 6. Default to Argon Theme (white/light mode)
uci set luci.main.mediaurlbase='/luci-static/argon' 2>/dev/null || true
uci commit luci 2>/dev/null || true

# 7. Automatically detect and configure Wi-Fi AP on first boot
if command -v wifi >/dev/null 2>&1; then
    wifi config
    uci set wireless.@wifi-device[0].disabled='0' 2>/dev/null || true
    uci set wireless.@wifi-iface[0].disabled='0' 2>/dev/null || true
    uci set wireless.@wifi-iface[0].network='lan' 2>/dev/null || true
    uci set wireless.@wifi-iface[0].ssid='TX9Pro-5G' 2>/dev/null || true
    uci commit wireless
fi

exit 0
EOF
chmod +x "${UCI_DIR}/99-tx9pro-custom-defaults"

echo "=== [8/8] Setup Complete! Ready to compile ==="
