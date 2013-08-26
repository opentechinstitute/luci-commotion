# Copyright (C) 2010 Commotion
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
include $(TOPDIR)/rules.mk

PKG_NAME:=commotion-debug-helper
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=git://github.com/opentechinstitute/commotion-bug-info.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_VERSION)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/commotion-debug-helper
  SECTION:=commotion
  CATEGORY:=Commotion
  TITLE:=Commotion Debug System
  DEPENDS:=+luci-commotion +luci-theme-commotion
  URL:=https://commotionwireless.net
endef

define Build/Compile
endef

define Package/commotion-debug-helper/description
  Commotion tool for generating a report file used for troubleshooting
endef

define Package/commotion-debug-helper/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/cdh.sh $(1)/usr/sbin/cdh || true
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/$(PKG_NAME)
	$(CP) $(PKG_BUILD_DIR)/luasrc/controller/* $(1)/usr/lib/lua/luci/controller/$(PKG_NAME)/ || true
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/$(PKG_NAME)
	$(CP) $(PKG_BUILD_DIR)/luasrc/view/* $(1)/usr/lib/lua/luci/view/$(PKG_NAME)/ || true
endef

$(eval $(call BuildPackage,commotion-debug-helper))
