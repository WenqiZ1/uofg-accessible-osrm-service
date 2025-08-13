#!/usr/bin/env bash
set -e

# 前台启动 OSRM（并行/自定义数据都已经在 build 时完成）
osrm-routed --algorithm mld /srv/map.osrm --port 5000 &

# 前台运行 nginx（作为 Render 对外的 10000 端口）
nginx -g 'daemon off;'
