FROM debian:bookworm-slim

# 基础依赖：OSRM 后端 + Nginx + tini + envsubst
RUN apt-get update && apt-get install -y --no-install-recommends \
    osrm-backend nginx ca-certificates curl tini gettext-base && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /srv

# 数据与脚本
COPY data/streets_single_fixed_with_highway_fixed.osm /srv/data/streets_single_fixed_with_highway_fixed.osm
COPY profiles/foot_all.lua         /srv/profiles/foot_all.lua
COPY profiles/foot_stepfree.lua    /srv/profiles/foot_stepfree.lua
COPY nginx.conf.template           /srv/nginx.conf.template
COPY start.sh                      /srv/start.sh
RUN chmod +x /srv/start.sh && mkdir -p /var/run/nginx

# —— 预处理 All-Access（CH）——
RUN mkdir -p /srv/all && \
    osrm-extract  -p /srv/profiles/foot_all.lua      /srv/data/streets_single_fixed_with_highway_fixed.osm && \
    osrm-contract     /srv/data/streets_single_fixed_with_highway_fixed.osrm && \
    mv /srv/data/* /srv/all/

# —— 预处理 Step-Free（CH）——
RUN mkdir -p /srv/stepfree && \
    osrm-extract  -p /srv/profiles/foot_stepfree.lua /srv/data/streets_single_fixed_with_highway_fixed.osm && \
    osrm-contract     /srv/data/streets_single_fixed_with_highway_fixed.osrm && \
    mv /srv/data/* /srv/stepfree/

ENV OSRM_ALL_DIR=/srv/all \
    OSRM_SF_DIR=/srv/stepfree

ENTRYPOINT ["/usr/bin/tini","-s","--"]
CMD ["/srv/start.sh"]
