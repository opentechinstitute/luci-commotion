include $(TOPDIR)/rules.mk

MODULE_NAME:=commotion-dash
MODULE_TITLE:=Commotion Dashboard Config

PKG_NAME:=luci-$(MODULE_NAME)
PKG_VERSION:=0.1
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=git://github.com/opentechinstitute/luci-commotion-dash.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_VERSION)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)


include $(INCLUDE_DIR)/package.mk

define Package/luci-$(MODULE_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=2. Modules
  TITLE:=LuCI Module - $(MODULE_TITLE)
  URL:=https://commotionwireless.net/
  DEPENDS:=+luci-commotion +commotion-bigboard-send
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-$(MODULE_NAME)/description
  Commotion dashboard plugin to project webGUI add-on
endef

define Package/luci-$(MODULE_NAME)/conffile
	/etc/config/commotion-dash
endef

define Package/luci-$(MODULE_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/$(MODULE_NAME)
	$(CP) $(PKG_BUILD_DIR)/luasrc/controller/$(MODULE_NAME)/* $(1)/usr/lib/lua/luci/controller/$(MODULE_NAME)/ 2>/dev/null || true
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/$(MODULE_NAME)
	$(CP) $(PKG_BUILD_DIR)/luasrc/view/$(MODULE_NAME)/* $(1)/usr/lib/lua/luci/view/$(MODULE_NAME)/ 2>/dev/null || true
endef

define Package/luci-$(MODULE_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	( . /etc/uci-defaults/luci-$(MODULE_NAME) ) && rm -f /etc/uci-defaults/luci-$(MODULE_NAME)
}
endef

$(eval $(call BuildPackage,luci-$(MODULE_NAME)))
