# service-stepfree/Dockerfile
FROM osrm/osrm-backend:latest

# 把 Glasgow 的 osm 数据放到镜像里（用你的 data 目录下的 .osm 文件即可）
COPY data/*.osm /srv/map.osm

# 使用 step-free 的 Lua
COPY profiles/foot_stepfree.lua /srv/foot.lua

# 预处理（extract/partition/customize）
RUN osrm-extract -p /srv/foot.lua /srv/map.osm && \
    osrm-partition /srv/map.osrm && \
    osrm-customize /srv/map.osrm

# 安装 nginx 及工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx ca-certificates curl tini gettext-base && \
    rm -rf /var/lib/apt/lists/*

# 拷贝 nginx 和启动脚本（注意路径从仓库根开始）
COPY service-stepfree/nginx.conf /etc/nginx/nginx.conf
COPY service-stepfree/start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
