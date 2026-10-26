include $(TOPDIR)/rules.mk

PKG_NAME:=ssv6x5x
PKG_RELEASE:=1

STAMP_CONFIGURED_DEPENDS := $(STAGING_DIR)/usr/include/mac80211-backport/backport/autoconf.h

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define KernelPackage/ssv6x5x
  SUBMENU:=Wireless Drivers
  TITLE:=iComm SV6256P / SSV6X5X SDIO WiFi
  DEPENDS:=+kmod-cfg80211 +kmod-mac80211 +kmod-mmc
  FILES:=$(PKG_BUILD_DIR)/ssv6x5x.ko
  AUTOLOAD:=$(call AutoProbe,ssv6x5x)
endef

NOSTDINC_FLAGS:= \
	$(KERNEL_NOSTDINC_FLAGS) \
	-I$(PKG_BUILD_DIR) \
	-I$(PKG_BUILD_DIR)/include \
	-I$(STAGING_DIR)/usr/include/mac80211-backport \
	-I$(STAGING_DIR)/usr/include/mac80211-backport/uapi \
	-I$(STAGING_DIR)/usr/include/mac80211 \
	-I$(STAGING_DIR)/usr/include/mac80211/uapi \
	-include backport/autoconf.h \
	-include backport/backport.h \
	-Wno-error=incompatible-pointer-types \
	-Wno-incompatible-pointer-types \
	-Wno-error

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	+$(KERNEL_MAKE) $(PKG_JOBS) \
		M="$(PKG_BUILD_DIR)" \
		NOSTDINC_FLAGS="$(NOSTDINC_FLAGS)" \
		ARCH="$(LINUX_KARCH)" \
		modules
endef

define KernelPackage/ssv6x5x/install
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/ssv6x5x-sw.bin $(1)/lib/firmware/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/ssv6x5x-wifi.cfg $(1)/lib/firmware/
endef

$(eval $(call KernelPackage,ssv6x5x))
