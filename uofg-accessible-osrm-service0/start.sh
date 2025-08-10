#!/usr/bin/env bash
set -euo pipefail

# 启动两套 osrm-routed（All:5000 / Step-Free:5001）
osrm-routed --algorithm ch --port 5000 "${OSRM_ALL_DIR}/streets_single_fixed_with_highway_fixed.osrm" &
ALL_PID=$!

osrm-routed --algorithm ch --port 5001 "${OSRM_SF_DIR}/streets_single_fixed_with_highway_fixed.osrm" &
SF_PID=$!

# 渲染并启动 Nginx（Render 传入 $PORT）
export PORT="${PORT:-8080}"
envsubst '$PORT' < /srv/nginx.conf.template > /etc/nginx/conf.d/default.conf
nginx -g 'daemon off;' &

wait -n $ALL_PID $SF_PID
