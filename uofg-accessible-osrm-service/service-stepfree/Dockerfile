FROM osrm-backend:latest

# 先更新源到 archive
RUN set -eux; \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid && \
    sed -i -E 's@//deb.debian.org/debian@//archive.debian.org/debian@g' /etc/apt/sources.list /etc/apt/sources.list.d/*.list || true && \
    sed -i -E 's@//security.debian.org/debian-security@//archive.debian.org/debian-security@g' /etc/apt/sources.list /etc/apt/sources.list.d/*.list || true && \
    apt-get update && \
    apt-get install -y --no-install-recommends nginx ca-certificates curl tini gettext-base && \
    rm -rf /var/lib/apt/lists/*

# 复制数据
COPY data/*.osm /srv/map.osm
COPY profiles/foot_stepfree.lua /srv/foot.lua

# OSRM 预处理
RUN osrm-extract -p /srv/foot.lua /srv/map.osm && \
    osrm-partition /srv/map.osrm && \
    osrm-customize /srv/map.osrm
