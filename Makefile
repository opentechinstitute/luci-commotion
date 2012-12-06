##################################################
# OpenWRT Makefile for Commotion De-Bugging Helper 
##################################################

include $(TOPDIR)/rules.mk

MODULE_NAME:=commotion
MODULE_TITLE:=Commotion

PKG_NAME:=$(MODULE_NAME)-debug-helper
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(MODULE_NAME)-debug-helper
  SECTION:=commotion
  CATEGORY:=Commotion
  TITLE:=Commotion De-Bugging Helper
  DEPENDS:=+commotionbase +luci
  URL:=http://commotionwireless.net/
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endif

define Package/$(MODULE_NAME)-debug-helper/description
	Commotion debugging data collection helper. Includes a LuCI user interface.
endif

define Package/$(MODULE_NAME)-debug-helper/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/cdh.sh $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/$(MODULE_NAME)
	$(CP) -a ./luasrc/controller/* $(1)/usr/lib/lua/luci/controller/$(MODULE_NAME)/  2>/dev/null || true
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/$(MODULE_NAME)
	$(CP) -a ./luasrc/view/* $(1)/usr/lib/lua/luci/view/ 2>/dev/null || true
endif

$(eval(call BuildPackage,$(MODULE_NAME)-debug-helper))