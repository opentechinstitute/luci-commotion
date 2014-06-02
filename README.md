luci-commotion
==============

Commotion configuration pages for the LuCI web interface.

luci-commotion is selected as a default build option in Commotion-Router (https://github.com/opentechinstitute/commotion-router)


## Roadmap

### Version 1.2

  * [Import / Export functionality for Commotiond profiles](https://github.com/opentechinstitute/luci-commotion/issues/88)
  * re-runnable setup wizard
  * [Status-page auto-updating values](https://github.com/opentechinstitute/luci-commotion/issues/162)
  * [Updated Nearby Mesh devices](https://github.com/opentechinstitute/luci-commotion/issues/137)
  * Command Line Setup Wizard (Possibly not in this repo as it will not be luci-based.)
  * [Babel Integration](https://github.com/opentechinstitute/luci-commotion/pull/200)

### Version 2.0

  * lua-info plugin for less memory-intesive access to OLSR info
  * [mesh-agnostic network-viz](https://lists.chambana.net/pipermail/commotion-dev/2014-February/001761.html)

luci-theme-commotion
=======================

The LuCI Commotion Theme was designed for the Commotion Wireless Project's openwrt-based software and is included by default in the commotion-feeds package, which is called by the commotion-router setup script.

Design changes should follow the Human Interface Guidelines described on the main project site.

This theme appears as luci-theme-commotion in Commotion-Router's menuconfig options

## Links

* <a href="http://commotionwireless.net">Commotion Wireless Project</a>
* <a href="https://commotionwireless.net/developer/hig/introduction">Commotion Human Interface Guidelines</a>
* <a href="https://github.com/opentechinstitute/commotion-router">Commotion-Router source code</a>
* <a href="https://github.com/opentechinstitute/commotion-feeds">Commotion-Feeds source code</a>
