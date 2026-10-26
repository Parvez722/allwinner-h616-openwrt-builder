#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${1:-.}"

echo "=== [1/6] Injecting iComm SV6256P / SSV6X5X Wi-Fi Package ==="
mkdir -p "${BUILD_DIR}/package/kernel"
cp -rf "${REPO_ROOT}/packages/ssv6x5x" "${BUILD_DIR}/package/kernel/"

echo "=== [2/6] Injecting Verified TX9 Pro / X96Q DDR3L Device Tree ==="
DTS_DIR="${BUILD_DIR}/target/linux/sunxi/files/arch/arm64/boot/dts/allwinner"
mkdir -p "${DTS_DIR}"
cp -vf "${REPO_ROOT}/patches/sun50i-h313-x96-q-v5.1.dts" "${DTS_DIR}/sun50i-h313-x96-q-v5.1.dts"

echo "=== [3/6] Injecting Ethernet AC300 / dwmac-sun8i Second EMAC Clock Patch ==="
for patch_dir in "${BUILD_DIR}/target/linux/sunxi/patches-6.12" "${BUILD_DIR}/target/linux/sunxi/patches-6.6"; do
    if [ -d "${patch_dir}" ]; then
        echo "Injecting 9785 dwmac patch into ${patch_dir}..."
        cp -vf "${REPO_ROOT}/patches/9785-drv-net-stmmac-dwmac-sun8i-second-EMAC-clock-register.patch" "${patch_dir}/"
    fi
done

echo "=== [4/6] Registering Device/x96q in target/linux/sunxi/image/cortexa53.mk ==="
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

echo "=== [5/6] Injecting Out-Of-The-Box Network & Wi-Fi Defaults ==="
UCI_DIR="${BUILD_DIR}/package/base-files/files/etc/uci-defaults"
mkdir -p "${UCI_DIR}"
cat << 'EOF' > "${UCI_DIR}/99-tx9pro-custom-defaults"
#!/bin/sh

# Set non-conflicting default LAN IP (192.168.1.99)
uci set network.lan.ipaddr='192.168.1.99'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway='192.168.1.1'
uci set network.lan.dns='1.1.1.1 8.8.8.8'
uci commit network

# Make LuCI and SSH accessible from LAN and WAN both
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

# Ensure uhttpd listens on all interfaces (LAN and WAN)
uci set uhttpd.main.listen_http='0.0.0.0:80'
uci commit uhttpd

# Enable serial console root access & dropbear
uci set dropbear.@dropbear[0].RootPasswordAuth='on' 2>/dev/null || true
uci set dropbear.@dropbear[0].GatewayPorts='on' 2>/dev/null || true
uci commit dropbear

# Automatically detect and configure Wi-Fi on first boot
if command -v wifi >/dev/null 2>&1; then
    wifi config
    uci set wireless.@wifi-device[0].disabled='0' 2>/dev/null || true
    uci set wireless.@wifi-iface[0].disabled='0' 2>/dev/null || true
    uci set wireless.@wifi-iface[0].ssid='TX9Pro-5G' 2>/dev/null || true
    uci commit wireless
fi

exit 0
EOF
chmod +x "${UCI_DIR}/99-tx9pro-custom-defaults"

echo "=== [6/6] Setup Complete! Ready to compile ==="
