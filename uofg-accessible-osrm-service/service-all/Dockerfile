FROM osrm/osrm-backend:latest

# 明确底图
COPY data/streets_fixed.osm /srv/all_access.osm
# 明确 profile
COPY profiles/foot_all.lua /srv/foot.lua

RUN osrm-extract   -p /srv/foot.lua /srv/all_access.osm && \
    osrm-partition    /srv/all_access.osrm && \
    osrm-customize    /srv/all_access.osrm

COPY service-all/start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
