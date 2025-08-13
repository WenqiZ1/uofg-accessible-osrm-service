# service-stepfree/Dockerfile
FROM osrm/osrm-backend:latest

# 1) 拷贝 Glasgow 的 .osm 到镜像
COPY data/*.osm /srv/map.osm

# 2) 使用 step-free 的 Lua
COPY profiles/foot_stepfree.lua /srv/foot.lua

# 3) 预处理（extract/partition/customize）
RUN osrm-extract -p /srv/foot.lua /srv/map.osm && \
    osrm-partition /srv/map.osrm && \
    osrm-customize /srv/map.osrm

# 4) 启动脚本
COPY service-stepfree/start.sh /start.sh
RUN chmod +x /start.sh

# 关键修复：去掉 CRLF，授权执行
RUN sed -i 's/\r$//' /start.sh /etc/nginx/nginx.conf && chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]


