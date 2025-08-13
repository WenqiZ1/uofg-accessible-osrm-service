# service-all/Dockerfile
FROM osrm/osrm-backend:latest

# 数据与 Lua
COPY data/*.osm /srv/map.osm
COPY profiles/foot_all.lua /srv/foot.lua

# 预处理
RUN osrm-extract -p /srv/foot.lua /srv/map.osm && \
    osrm-partition /srv/map.osrm && \
    osrm-customize /srv/map.osrm

# 启动脚本（无 nginx）
COPY service-all/start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
