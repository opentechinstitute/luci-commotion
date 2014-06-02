include $(TOPDIR)/rules.mk

THEME_NAME:=commotion
THEME_TITLE:=Commotion

PKG_NAME:=luci-theme-$(THEME_NAME)
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=git://github.com/opentechinstitute/commotion-openwrt-theme.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_VERSION)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/luci-theme-$(THEME_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=4. Themes
  DEPENDS:=+luci-theme-base
  TITLE:=LuCI Theme - $(THEME_TITLE)
  URL:=https://www.commotionwireless.net/
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-theme-$(THEME_NAME)/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	echo "uci set luci.themes.$(THEME_TITLE)=/luci-static/$(THEME_NAME); uci set luci.main.mediaurlbase=/luci-static/$(THEME_NAME); uci commit luci" > $(1)/etc/uci-defaults/luci-theme-$(THEME_NAME)
	$(INSTALL_DIR) $(1)/www/luci-static/$(THEME_NAME)
	$(CP) $(PKG_BUILD_DIR)/files/htdocs/* $(1)/www/luci-static/$(THEME_NAME)/ 2>/dev/null || true
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/themes/$(THEME_NAME)
	$(CP) $(PKG_BUILD_DIR)/files/templates/* $(1)/usr/lib/lua/luci/view/themes/$(THEME_NAME)/ 2>/dev/null || true
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/cbi
	$(CP) $(PKG_BUILD_DIR)/luasrc/view/cbi/* $(1)/usr/lib/lua/luci/view/cbi/ 2>/dev/null || true
endef

define Package/luci-theme-$(THEME_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	( . /etc/uci-defaults/luci-theme-$(THEME_NAME) ) && rm -f /etc/uci-defaults/luci-theme-$(THEME_NAME)
}
endef

$(eval $(call BuildPackage,luci-theme-$(THEME_NAME)))
