# 使用官方 OSRM 后端镜像
FROM osrm/osrm-backend:latest

# 安装 nginx
RUN apt-get update && apt-get install -y --no-install-recommends nginx ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# 拷贝数据与脚本
# 假设 data 目录里只有一个 .osm 或 .pbf 文件
COPY data/*.osm /data/map.osm
# 如果你是 .pbf，就写成：COPY data/*.pbf /data/map.pbf  并把下面的 /data/map.osm 换成对应的
COPY profiles/foot_all.lua      /profiles/foot_all.lua
COPY profiles/foot_stepfree.lua /profiles/foot_stepfree.lua
COPY nginx.conf /etc/nginx/nginx.conf
COPY start.sh   /start.sh


# 预处理：分别用两个 profile 提取、分区、定制，输出到两处
RUN mkdir -p /srv/osrm/all /srv/osrm/sf && \
    osrm-extract   -p /profiles/foot_all.lua      /data/map.osm -o /srv/osrm/all/map.osrm && \
    osrm-partition     /srv/osrm/all/map.osrm && osrm-customize /srv/osrm/all/map.osrm && \
    osrm-extract   -p /profiles/foot_stepfree.lua /data/map.osm -o /srv/osrm/sf/map.osrm  && \
    osrm-partition     /srv/osrm/sf/map.osrm  && osrm-customize /srv/osrm/sf/map.osrm  && \
    rm -rf /data /profiles

# 拷贝 nginx 配置与启动脚本
COPY service-stepfree/nginx.conf /etc/nginx/nginx.conf
COPY service-stepfree/start.sh   /start.sh
RUN chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
