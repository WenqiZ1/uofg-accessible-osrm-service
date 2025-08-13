#!/usr/bin/env sh
set -eux

# Render 会注入 PORT 环境变量；本地无则用 10000
PORT="${PORT:-10000}"

# 直接启动 osrm-routed；使用 MLD（和我们上面的 partition/customize 一致）
exec osrm-routed \
  --algorithm mld \
  --port "${PORT}" \
  /srv/map.osrm
