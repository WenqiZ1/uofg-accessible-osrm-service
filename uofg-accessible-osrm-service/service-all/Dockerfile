# service-all/Dockerfile
FROM osrm/osrm-backend:latest

# 数据与 Lua
COPY data/*.osm /srv/map.osm
COPY profiles/foot_all.lua /srv/foot.lua

RUN osrm-extract   -p /srv/foot.lua /srv/all_access.osm && \
    osrm-partition    /srv/all_access.osrm && \
    osrm-customize    /srv/all_access.osrm

COPY service-all/start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
