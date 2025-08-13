FROM osrm/osrm-backend:latest
WORKDIR /srv
COPY /data/streets_single_fixed_with_highway_fixed.osm /srv/map.osm
COPY /profiles/foot_all.lua /srv/foot.lua
RUN osrm-extract -p /srv/foot.lua /srv/map.osm \
 && osrm-contract /srv/map.osrm
# Render 会注入环境变量 PORT；默认 8080 方便本地测试
CMD sh -lc 'osrm-routed --algorithm ch --port ${PORT:-8080} /srv/map.osrm'
