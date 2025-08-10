#!/usr/bin/env bash
set -euo pipefail

osrm-routed --algorithm ch --port 5000 "${OSRM_ALL_DIR}/glasgow.osrm" &
ALL_PID=$!

osrm-routed --algorithm ch --port 5001 "${OSRM_SF_DIR}/glasgow.osrm" &
SF_PID=$!

export PORT="${PORT:-8080}"
envsubst '$PORT' < /srv/nginx.conf.template > /etc/nginx/conf.d/default.conf

nginx -g 'daemon off;' &

wait -n $ALL_PID $SF_PID
