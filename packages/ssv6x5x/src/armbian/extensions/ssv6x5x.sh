#!/bin/bash
# Armbian extension for SSV6X5X (SV6256P) WiFi driver
# Place this file in userpatches/extensions/ and enable with:
#   ENABLE_EXTENSIONS="ssv6x5x"

function extension_prepare_config__ssv6x5x() {
	display_alert "Preparing SSV6X5X WiFi driver" "ssv6x5x" "info"

	# Ensure DKMS is available in the target image
	declare -g EXTRA_PACKAGES_ROOTFS="${EXTRA_PACKAGES_ROOTFS} dkms"
}

function post_install_kernel_debs__install_ssv6x5x() {
	display_alert "Installing SSV6X5X DKMS driver" "ssv6x5x" "info"

	local driver_name="ssv6x5x"
	local driver_src_dir="${EXTENSION_DIR}"
	local driver_version
	driver_version=$(sed -n 's/^PACKAGE_VERSION="\(.*\)"$/\1/p' "${driver_src_dir}/dkms.conf")
	local driver_dest="${SDCARD}/usr/src/${driver_name}-${driver_version}"

	# Copy driver source (exclude unnecessary files)
	mkdir -p "${driver_dest}"
	rsync -a \
		--exclude='.git' \
		--exclude='*.o' \
		--exclude='*.ko' \
		--exclude='*.mod*' \
		--exclude='.tmp_versions' \
		--exclude='Module.symvers' \
		--exclude='modules.order' \
		--exclude='tags' \
		--exclude='armbian/' \
		"${driver_src_dir}/" "${driver_dest}/"

	# Install firmware files
	local fw_dir="${SDCARD}/lib/firmware"
	mkdir -p "${fw_dir}"
	cp -f "${driver_src_dir}/${driver_name}-sw.bin" "${fw_dir}/"
	cp -f "${driver_src_dir}/${driver_name}-wifi.cfg" "${fw_dir}/"
	# Also copy from image/ directory if available
	if [ -f "${driver_src_dir}/image/${driver_name}-sw.bin" ]; then
		cp -f "${driver_src_dir}/image/${driver_name}-sw.bin" "${fw_dir}/"
	fi

	# Register and build with DKMS inside the chroot
	chroot_sdcard dkms add "${driver_name}/${driver_version}"

	# Build for the installed kernel
	local target_kernel_version
	target_kernel_version=$(ls "${SDCARD}/lib/modules/" | head -1)

	if [ -n "${target_kernel_version}" ]; then
		display_alert "Building SSV6X5X for kernel" "${target_kernel_version}" "info"
		chroot_sdcard dkms build "${driver_name}/${driver_version}" -k "${target_kernel_version}"
		chroot_sdcard dkms install "${driver_name}/${driver_version}" -k "${target_kernel_version}"
	else
		display_alert "No kernel found, DKMS will build on first boot" "ssv6x5x" "warn"
	fi

	# Enable auto-loading
	echo "${driver_name}" >> "${SDCARD}/etc/modules-load.d/${driver_name}.conf"

	display_alert "SSV6X5X driver installed" "ssv6x5x" "info"
}
