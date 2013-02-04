# Copyright (C) 2010 Commotion
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
include $(TOPDIR)/rules.mk

PKG_NAME:=commotion-debug-helper
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

include $(INCLUDE_DIR)/package.mk

define Package/commotion-debug-helper
  SECTION:=commotion
  CATEGORY:=Commotion
  TITLE:=Commotion Debug System
  DEPENDS:=+commotionbase
  URL:=http://commotionwireless.net
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/commotion-debug-helper/description
  Commotion rapid-deployment infrastructure
endef

define Package/commotion-debug-helper/install
	echo "Testing"
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) ./files/cdh.sh $(1)/usr/sbin/cdh || true
	$(CP) -a  ./luasrc/controller/* $(1)/usr/lib/lua/luci/controller/$(PKG_NAME)/ || true
	$(CP) -a ./luasrc/view/* $(1)/usr/lib/lua/luci/view/$(PKG_NAME)/ || true
endef

$(eval $(call BuildPackage,commotion-debug-helper))
