#!/usr/bin/env sh
set -eux
PORT="${PORT:-10000}"
# 打印签名，便于在日志中确认确实跑的是 ALL ACCESS
md5sum /srv/foot.lua /srv/all_access.osm || true
head -n 20 /srv/foot.lua || true

exec osrm-routed --algorithm mld --port "$PORT" /srv/all_access.osrm
