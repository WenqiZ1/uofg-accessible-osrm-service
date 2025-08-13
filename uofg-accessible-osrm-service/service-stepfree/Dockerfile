# 使用 OSRM 后端镜像（建议固定版本更稳）
FROM osrm/osrm-backend:latest

# FROM osrm/osrm-backend:latest

# —— 修正 Debian 源到 archive，并移除 stretch-updates，允许过期索引 —— 
RUN set -eux; \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid; \
    # 把 deb/security 都指向 archive
    sed -i -E 's@//deb\.debian\.org/debian@//archive.debian.org/debian@g' \
        /etc/apt/sources.list /etc/apt/sources.list.d/*.list || true; \
    sed -i -E 's@//security\.debian\.org/debian-security@//archive.debian.org/debian-security@g' \
        /etc/apt/sources.list /etc/apt/sources.list.d/*.list || true; \
    # 删除 stretch-updates（archive 没有这个目录）
    sed -i -E '/stretch-updates/d' /etc/apt/sources.list /etc/apt/sources.list.d/*.list || true; \
    # 允许过期索引并更新
    apt-get -o Acquire::Check-Valid-Until=false -o Acquire::AllowInsecureRepositories=true update; \
    apt-get install -y --no-install-recommends nginx ca-certificates curl tini gettext-base; \
    rm -rf /var/lib/apt/lists/*


# —— 拷贝 Glasgow 的 .osm 数据 —— 
# 注意：源路径使用仓库根相对路径，带目录前缀更稳
COPY data/*.osm /srv/map.osm

# —— 拷贝 step-free 的 profile —— 
COPY profiles/foot_stepfree.lua /srv/foot.lua

# —— 预处理（extract/partition/customize）——
RUN osrm-extract -p /srv/foot.lua /srv/map.osm && \
    osrm-partition /srv/map.osrm && \
    osrm-customize /srv/map.osrm

# —— 拷贝 Nginx 配置与启动脚本 —— 
# 这里确保源路径写成 service-stepfree/ 前缀（因为 build 上下文是仓库根）
COPY service-stepfree/nginx.conf /etc/nginx/nginx.conf
COPY service-stepfree/start.sh  /start.sh
RUN chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]



