FROM osrm/osrm-backend:latest

# 1) 拷贝与你本地一致的 PBF
COPY data/streets_single_fixed_with_highway_fixed.osm.pbf /srv/all_access.osm.pbf

# 2) 拷贝 All Access 的 profile（此处用 foot_all.lua）
COPY profiles/foot_all.lua /srv/foot.lua

# 3) 预处理
RUN osrm-extract -p /srv/foot.lua /srv/all_access.osm.pbf && \
    osrm-partition /srv/all_access.osrm && \
    osrm-customize /srv/all_access.osrm

# 4) 启动
COPY service-all/start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]

