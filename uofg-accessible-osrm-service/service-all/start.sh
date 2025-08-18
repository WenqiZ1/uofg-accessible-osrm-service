#!/usr/bin/env sh
set -eux
PORT="${PORT:-10000}"

# 打印签名，严防“以为换了，其实没换”
md5sum /srv/foot.lua /srv/all_access.osm || true
head -n 20 /srv/foot.lua || true

exec osrm-routed --algorithm mld --port "$PORT" /srv/all_access.osrm
