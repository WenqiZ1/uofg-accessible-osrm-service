# service-all/Dockerfile
FROM osrm/osrm-backend:latest

COPY data/*.osm /srv/map.osm
COPY profiles/foot_all.lua /srv/foot.lua

RUN osrm-extract -p /srv/foot.lua /srv/map.osm && \
    osrm-partition /srv/map.osrm && \
    osrm-customize /srv/map.osrm

# —— 修正 Debian 源到 archive，并关闭有效期检查 ——
RUN set -eux; \
  echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid && \
  sed -i -E 's@//deb\.debian\.org/debian@//archive.debian.org/debian@g' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true && \
  sed -i -E 's@//security\.debian\.org/debian-security@//archive.debian.org/debian-security@g' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true && \
  apt-get update && \
  apt-get install -y --no-install-recommends nginx ca-certificates curl tini gettext-base && \
  rm -rf /var/lib/apt/lists/*
