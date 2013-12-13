#!/bin/sh
# Cheater script to get around luci.sys.exec and luci.util.exec issues
# Takes json_info_host and json_info_port from commotion-bigboard-send
# Should be possible to write a proper luci connection
echo "\r\n" | nc "$1" "$2"
