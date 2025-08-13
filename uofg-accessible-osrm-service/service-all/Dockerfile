# service-all/Dockerfile
FROM osrm/osrm-backend:latest

# 1) 拷贝 Glasgow 的 .osm 数据到镜像
COPY data/*.osm /srv/map.osm

# 2) 使用 All Access 的 Lua
COPY profiles/foot_all.lua /srv/foot.lua

# 3) 预处理（extract / partition / customize）
RUN osrm-extract -p /srv/foot.lua /srv/map.osm && \
    osrm-partition /srv/map.osrm && \
    osrm-customize /srv/map.osrm

# 4) 启动脚本
COPY service-all/start.sh /start.sh

# 去掉 CRLF 并赋予执行权限（**不要**再动什么 nginx.conf）
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
