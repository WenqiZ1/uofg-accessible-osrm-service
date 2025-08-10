FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    osrm-backend nginx ca-certificates curl tini && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /srv
COPY data/glasgow-campus.osm.pbf /srv/data/glasgow-campus.osm.pbf
COPY profiles/foot_all.lua /srv/profiles/foot_all.lua
COPY profiles/foot_stepfree.lua /srv/profiles/foot_stepfree.lua
COPY nginx.conf.template /srv/nginx.conf.template
COPY start.sh /srv/start.sh
RUN chmod +x /srv/start.sh && mkdir -p /var/run/nginx

# 预处理 All-Access
RUN mkdir -p /srv/all && \
    osrm-extract -p /srv/profiles/foot_all.lua /srv/data/glasgow-campus.osm.pbf && \
    osrm-contract /srv/data/glasgow-campus.osrm && \
    mv /srv/data/* /srv/all/

# 预处理 Step-Free
RUN mkdir -p /srv/stepfree && \
    osrm-extract -p /srv/profiles/foot_stepfree.lua /srv/data/glasgow-campus.osm.pbf && \
    osrm-contract /srv/data/glasgow-campus.osrm && \
    mv /srv/data/* /srv/stepfree/

ENV OSRM_ALL_DIR=/srv/all \
    OSRM_SF_DIR=/srv/stepfree

ENTRYPOINT ["/usr/bin/tini","-s","--"]
CMD ["/srv/start.sh"]
