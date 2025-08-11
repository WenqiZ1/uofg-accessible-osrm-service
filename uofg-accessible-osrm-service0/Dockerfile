FROM osrm/osrm-backend:latest

# 仅补充我们需要的工具：nginx + tini + envsubst
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx ca-certificates curl tini gettext-base && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /srv

# 数据与脚本
COPY data/streets_single_fixed_with_highway_fixed.osm /srv/data/streets_single_fixed_with_highway_fixed.osm
COPY profiles/foot_all.lua         /srv/profiles/foot_all.lua
COPY profiles/foot_stepfree.lua    /srv/profiles/foot_stepfree.lua
COPY nginx.conf.template           /srv/nginx.conf.template
COPY start.sh                      /srv/start.sh
RUN chmod +x /srv/start.sh && mkdir -p /var/run/nginx /srv/all /srv/stepfree

# —— 预处理 All-Access（CH）——
RUN osrm-extract -p /srv/profiles/foot_all.lua /srv/data/streets_single_fixed_with_highway_fixed.osm && \
    osrm-contract /srv/streets_single_fixed_with_highway_fixed.osrm && \
    mv /srv/*.osrm* /srv/all/

# —— 预处理 Step-Free（CH）——
RUN osrm-extract -p /srv/profiles/foot_stepfree.lua /srv/data/streets_single_fixed_with_highway_fixed.osm && \
    osrm-contract /srv/streets_single_fixed_with_highway_fixed.osrm && \
    mv /srv/*.osrm* /srv/stepfree/

ENV OSRM_ALL_DIR=/srv/all \
    OSRM_SF_DIR=/srv/stepfree

ENTRYPOINT ["/usr/bin/tini","-s","--"]
CMD ["/srv/start.sh"]
