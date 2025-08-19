# service-stepfree/Dockerfile
FROM osrm/osrm-backend:latest

COPY data/streets_single_fixed_with_highway_fixed.osm /srv/map.osm

COPY profiles/foot_stepfree.lua /srv/foot.lua

RUN osrm-extract -p /srv/foot.lua /srv/step_free.osm && \
    osrm-partition /srv/step_free.osrm && \
    osrm-customize /srv/step_free.osrm

COPY service-stepfree/start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh
EXPOSE 10000
CMD ["/start.sh"]



