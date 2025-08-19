# service-stepfree/Dockerfile
FROM osrm/osrm-backend:latest

# 1) 拷贝 Glasgow 的 .osm 到镜像
COPY data/streets_single_fixed_with_highway.osm /srv/map.osm

# 2) 使用 step-free 的 Lua
COPY profiles/foot_stepfree.lua /srv/foot.lua

# 3) 预处理（extract/partition/customize）
RUN osrm-extract -p /srv/foot.lua /srv/map.osm && \
    osrm-partition /srv/map.osrm && \
    osrm-customize /srv/map.osrm

# 4) 启动脚本
COPY service-stepfree/start.sh /start.sh

# 关键修复：去掉 CRLF，并授予执行权限（不再处理 nginx.conf）
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]

