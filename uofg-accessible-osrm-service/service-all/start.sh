#!/usr/bin/env sh
set -eux

PORT="${PORT:-10000}"

exec osrm-routed \
  --algorithm mld \
  --port "${PORT}" \
  /srv/map.osrm

