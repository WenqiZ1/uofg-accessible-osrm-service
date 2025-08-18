FROM osrm/osrm-backend:latest

# 显式指定底图（若你希望复刻历史5000，用 streets_single_fixed.osm；否则就同一份底图做AB对比）
COPY data/streets_fixed.osm /srv/all_access.osm
COPY profiles/foot_all.lua         /srv/foot.lua

RUN osrm-extract   -p /srv/foot.lua /srv/all_access.osm && \
    osrm-partition    /srv/all_access.osrm && \
    osrm-customize    /srv/all_access.osrm

COPY service-all/start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
