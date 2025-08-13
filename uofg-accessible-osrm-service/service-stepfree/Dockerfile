# service-stepfree/Dockerfile
FROM osrm/osrm-backend:latest

# 把 Glasgow 的 osm 数据放到镜像里（用你的 data 目录下的 .osm 文件即可）
COPY data/*.osm /srv/map.osm

# 使用 step-free 的 Lua
COPY profiles/foot_stepfree.lua /srv/foot.lua

# 预处理（extract/partition/customize）
RUN osrm-extract -p /srv/foot.lua /srv/map.osm && \
    osrm-partition /srv/map.osrm && \
    osrm-customize /srv/map.osrm

RUN set -eux; \
  echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid && \
  sed -i -E 's@//deb\.debian\.org/debian@//archive.debian.org/debian@g' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true && \
  sed -i -E 's@//security\.debian\.org/debian-security@//archive.debian.org/debian-security@g' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true && \
  apt-get update && \
  apt-get install -y --no-install-recommends nginx ca-certificates curl tini gettext-base && \
  rm -rf /var/lib/apt/lists/*

