#!/usr/bin/env bash
# Custom post-install script for X96Q / TX9 Pro

echo ">>> [1/7] Installing essential networking tools: network-manager (nmcli/nmtui), wireless-tools, etc..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends \
    network-manager \
    wireless-tools \
    wpasupplicant \
    ethtool \
    curl \
    wget \
    htop \
    nano \
    usbutils \
    pciutils \
    rfkill \
    iputils-ping \
    dnsutils \
    net-tools \
    iperf3 \
    bash-completion

# 2. Install SV6256P Wi-Fi driver and firmware (safely without breaking UsrMerge)
if [[ -f /tmp/overlay/x96q-sv6256p-wifi_1.0_arm64.deb ]]; then
    echo ">>> [2/7] Safely extracting SV6256P Wi-Fi package..."
    mkdir -p /tmp/wifi_pkg
    dpkg -x /tmp/overlay/x96q-sv6256p-wifi_1.0_arm64.deb /tmp/wifi_pkg
    mkdir -p /usr/lib/firmware
    cp -vf /tmp/wifi_pkg/lib/firmware/* /usr/lib/firmware/ 2>/dev/null || true
    KVER=$(ls /lib/modules 2>/dev/null | head -n 1)
    if [[ -n "$KVER" ]]; then
        mkdir -p /lib/modules/$KVER/kernel/drivers/net/wireless/
        cp -vf /tmp/wifi_pkg/lib/modules/*/kernel/drivers/net/wireless/ssv6x5x.ko /lib/modules/$KVER/kernel/drivers/net/wireless/ 2>/dev/null || true
        depmod -a "$KVER" 2>/dev/null || true
    fi
    rm -rf /tmp/wifi_pkg
fi

# 3. Install LAN Fixed Device Tree
if [[ -f /tmp/overlay/sun50i-h313-x96-q-v5.1-lanfixed.dtb ]]; then
    echo ">>> [3/7] Installing verified LAN-fixed device tree..."
    mkdir -p /boot/dtb/allwinner
    cp -vf /tmp/overlay/sun50i-h313-x96-q-v5.1-lanfixed.dtb /boot/dtb/allwinner/sun50i-h313-x96-q-v5.1.dtb
    for d in /boot/dtb-*; do
        if [[ -d "$d/allwinner" ]]; then
            cp -vf /tmp/overlay/sun50i-h313-x96-q-v5.1-lanfixed.dtb "$d/allwinner/sun50i-h313-x96-q-v5.1.dtb"
        fi
    done
fi

# 4. Install patched dwmac-sun8i Ethernet driver (with verified H616 EMAC1 syscon support)
if [[ -f /tmp/overlay/dwmac-sun8i.ko ]]; then
    echo ">>> [4/7] Installing verified patched dwmac-sun8i module..."
    KVER=$(ls /lib/modules 2>/dev/null | head -n 1)
    if [[ -n "$KVER" ]]; then
        mkdir -p /lib/modules/$KVER/kernel/drivers/net/ethernet/stmicro/stmmac/
        cp -vf /tmp/overlay/dwmac-sun8i.ko /lib/modules/$KVER/kernel/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.ko
        depmod -a "$KVER" 2>/dev/null || true
    fi
fi

# 5. Disable conflicting wireless services
echo ">>> [5/7] Disabling conflicting Unisoc/AW859A services..."
systemctl disable aw859a-wifi.service 2>/dev/null || true
systemctl disable aw859a-bluetooth.service 2>/dev/null || true
systemctl mask aw859a-wifi.service 2>/dev/null || true

# 6. Ensure ssv6x5x is loaded on boot
mkdir -p /etc/modules-load.d
echo "ssv6x5x" > /etc/modules-load.d/ssv6x5x.conf

# 7. Configure NetworkManager & Out-of-the-box Root Login
echo ">>> [6/7] Configuring NetworkManager..."
mkdir -p /etc/NetworkManager/conf.d
cat << 'NMEOF' > /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
[keyfile]
unmanaged-devices=none
NMEOF

systemctl enable NetworkManager

echo ">>> [7/7] Setting non-expiring root credentials (root / 1234)..."
echo "root:1234" | chpasswd
chage -d 20000 -m 0 -M 99999 -W 7 root || true
rm -f /root/.not_logged_in_yet

echo ">>> Custom hardware fixes applied successfully!"
