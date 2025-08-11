#!/usr/bin/env bash
set -e

# 把 nginx 日志接到容器标准输出
ln -sf /dev/stdout /var/log/nginx/access.log || true
ln -sf /dev/stderr /var/log/nginx/error.log  || true

# 启动两份 OSRM（MLD）
# All Access → 5000
osrm-routed --algorithm mld --port 5000 /srv/osrm/all/map.osrm &

# Step-Free → 5001
osrm-routed --algorithm mld --port 5001 /srv/osrm/sf/map.osrm  &

# 等待两端口就绪（最多各 30s）
for port in 5000 5001; do
  for i in {1..30}; do
    if curl -fs "http://127.0.0.1:${port}/nearest/v1/foot/-4.29,55.87" >/dev/null 2>&1; then
      echo "OSRM ${port} ready"; break
    fi
    echo "Waiting OSRM ${port}..."; sleep 1
  done
done

# 前台运行 nginx
nginx -g 'daemon off;'
