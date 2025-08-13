#!/bin/sh
set -e

# 启动 OSRM
osrm-routed --algorithm mld /data/map.osrm &

# 启动 Nginx
nginx -g "daemon off;"
