FROM osrm/osrm-backend:latest
WORKDIR /srv
# 这里从“上一级”取 data 和 profiles
COPY ../data/streets_single_fixed_with_highway_fixed.osm /srv/map.osm
COPY ../profiles/foot_all.lua /srv/foot.lua
RUN osrm-extract -p /srv/foot.lua /srv/map.osm \
 && osrm-contract /srv/map.osrm
CMD sh -lc 'osrm-routed --algorithm ch --port ${PORT:-8080} /srv/map.osrm'
