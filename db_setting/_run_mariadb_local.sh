#!/usr/bin/bash

echo "================================================"
echo "Starting MariaDB Local(Dev) Container"
echo "================================================"

docker run --name mariadb_dev \
    -e 'MYSQL_ROOT_PASSWORD=root' \
    -e TZ=Asia/Seoul \
    -p 33333:3306 \
    --restart always \
    -d mariadb:11.4 \
    --character-set-server=utf8 \
    --collation-server=utf8_general_ci

if [ $? -eq 0 ]; then
    echo "✓ MariaDB container started successfully"
    echo ""
    echo "Container Status:"
    docker ps -f name=mariadb_dev
    echo ""
    echo "Access Methods:"
    echo "  - Docker exec: docker exec -it mariadb_dev mariadb -u root -p"
else
    echo "✗ Failed to start MariaDB container"
    exit 1
fi      


# docker run --name {container_name} \
#     -e 'MYSQL_ROOT_PASSWORD=vW7fzQi78BCCojG' \
#     -v ./volumes/mariadb:/var/lib/mysql:rw \
#     -v ./volumes/mariadb/etc/mariadb/conf.d:/etc/mysql/conf.d \
#     # -v /etc/localtime:/etc/localtime:ro \
#     -e TZ=Asia/Seoul \
#     --p 13306:3306 \
#     --network=(만약에 있으면) \
#     --restart always \
#     -d mariadb:10.6.17      