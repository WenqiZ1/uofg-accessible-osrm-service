# service-all/Dockerfile
FROM osrm/osrm-backend:latest

COPY data/*.osm /srv/map.osm
COPY profiles/foot_all.lua /srv/foot.lua

RUN osrm-extract -p /srv/foot.lua /srv/map.osm && \
    osrm-partition /srv/map.osrm && \
    osrm-customize /srv/map.osrm

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx ca-certificates curl tini gettext-base && \
    rm -rf /var/lib/apt/lists/*

COPY service-all/nginx.conf /etc/nginx/nginx.conf
COPY service-all/start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
