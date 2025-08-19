# service-all/Dockerfile
FROM osrm/osrm-backend:latest

# 用与你本地一致的 PBF
COPY data/glasgow.osm.pbf /srv/all_access.osm.pbf

# 复制你自己的 foot.lua（v2，带 require）
COPY profiles/foot.lua /srv/foot.lua

# 关键：把 OSRM 的 profiles/lib 复制到镜像里，供 require("lib/...") 使用
# （不同镜像路径略有差异，下面写一个“就近拷贝”的探测）
RUN set -eux; \
  for p in /opt/osrm-backend/profiles/lib /opt/osrm/profiles/lib /usr/local/share/osrm/profiles/lib; do \
    if [ -d "$p" ]; then mkdir -p /srv/lib && cp -r "$p"/* /srv/lib/ && exit 0; fi; \
  done; \
  echo "OSRM lib not found" && exit 1

# 可选：补充 Lua 搜索路径（一般不需要，require 会以相对路径找 lib/）
ENV LUA_PATH="/srv/?.lua;/srv/?/init.lua;/srv/lib/?.lua;/srv/lib/?/init.lua;;"

# 预处理
RUN osrm-extract -p /srv/foot.lua /srv/all_access.osm.pbf && \
    osrm-partition /srv/all_access.osrm && \
    osrm-customize /srv/all_access.osrm

# 启动脚本
COPY service-all/start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
