#!/usr/bin/env sh
set -eux

# 启动前列出 /srv，确认 .osrm 产物确实存在
ls -l /srv || true
md5sum /srv/foot.lua /srv/map.osm || true
head -n 12 /srv/foot.lua || true
echo "THIS IS STEP-FREE"

PORT="${PORT:-10000}"
exec osrm-routed --algorithm mld --port "$PORT" /srv/map.osrm
