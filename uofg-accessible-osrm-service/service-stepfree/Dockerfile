# service-stepfree/Dockerfile
FROM osrm/osrm-backend:latest

# 1) 数据
COPY data/streets_single_fixed_with_highway_fixed.osm /srv/step_free.osm

# 2) Lua
COPY profiles/foot_stepfree.lua /srv/foot.lua

# 3) 预处理（名称保持 step_free 前缀）
RUN osrm-extract -p /srv/foot.lua /srv/step_free.osm && \
    osrm-partition /srv/step_free.osrm && \
    osrm-customize /srv/step_free.osrm

# 4) 启动
COPY service-stepfree/start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh
EXPOSE 10000
CMD ["/start.sh"]



