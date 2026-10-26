#!/bin/bash
# install-dkms.sh — Install SSV6X5X WiFi driver via DKMS
# Usage: sudo ./install-dkms.sh

set -e

DRIVER_NAME="ssv6x5x"
# Read version dynamically from dkms.conf
DRIVER_VERSION=$(sed -n 's/^PACKAGE_VERSION="\(.*\)"$/\1/p' "$(dirname "$0")/dkms.conf")
if [ -z "$DRIVER_VERSION" ]; then
    echo "Error: Could not read PACKAGE_VERSION from dkms.conf"
    exit 1
fi
SRC_DIR="/usr/src/${DRIVER_NAME}-${DRIVER_VERSION}"

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root (sudo)."
    exit 1
fi

# Check dkms
if ! command -v dkms &> /dev/null; then
    echo "Error: dkms is not installed. Install it with:"
    echo "  Debian/Ubuntu: sudo apt-get install dkms"
    echo "  Arch Linux:    sudo pacman -S dkms"
    echo "  Fedora/RHEL:   sudo dnf install dkms"
    exit 1
fi

# Remove previous installation if exists
if dkms status "${DRIVER_NAME}/${DRIVER_VERSION}" 2>/dev/null | grep -q "${DRIVER_NAME}"; then
    echo ">> Removing previous DKMS installation..."
    dkms remove "${DRIVER_NAME}/${DRIVER_VERSION}" --all || true
fi

# Copy source to /usr/src
echo ">> Copying driver source to ${SRC_DIR}..."
rm -rf "${SRC_DIR}"
mkdir -p "${SRC_DIR}"

# Copy only necessary files (exclude .git, build artifacts, etc.)
rsync -a --exclude='.git' --exclude='*.o' --exclude='*.ko' --exclude='*.mod*' \
    --exclude='.tmp_versions' --exclude='Module.symvers' --exclude='modules.order' \
    --exclude='tags' \
    "$(dirname "$(readlink -f "$0")")/" "${SRC_DIR}/"

# Install firmware
echo ">> Installing firmware files..."
cp -f "${SRC_DIR}/${DRIVER_NAME}-sw.bin" /lib/firmware/
cp -f "${SRC_DIR}/${DRIVER_NAME}-wifi.cfg" /lib/firmware/

# DKMS add, build, install
echo ">> Adding to DKMS..."
dkms add "${DRIVER_NAME}/${DRIVER_VERSION}"

echo ">> Building module..."
dkms build "${DRIVER_NAME}/${DRIVER_VERSION}"

echo ">> Installing module..."
dkms install "${DRIVER_NAME}/${DRIVER_VERSION}"

echo ""
echo "========================================="
echo " SSV6X5X driver installed successfully!"
echo " Load with: sudo modprobe ${DRIVER_NAME}"
echo "========================================="
