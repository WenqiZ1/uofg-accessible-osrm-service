#!/usr/bin/env sh
set -eux
md5sum /srv/foot.lua /srv/*.osm* || true
head -n 10 /srv/foot.lua || true
PORT="${PORT:-10000}"
exec osrm-routed --algorithm mld --port "$PORT" /srv/all_access.osrm
