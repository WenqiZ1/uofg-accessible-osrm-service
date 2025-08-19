FROM osrm/osrm-backend:latest

# 1) 数据：精确写你仓库里存在的文件名
COPY data/streets_single_fixed_with_highway_fixed.osm /srv/map.osm

# 2) Profile（确保 api_version = 4 且文件末尾有 return 表）
COPY profiles/foot_stepfree.lua /srv/foot.lua

# 3) 预处理（输入/输出全部使用 map 前缀）
RUN osrm-extract  -p /srv/foot.lua /srv/map.osm && \
    osrm-partition             /srv/map.osrm && \
    osrm-customize             /srv/map.osrm

# 4) 启动脚本
COPY service-stepfree/start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
