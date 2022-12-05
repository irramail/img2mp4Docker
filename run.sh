#!/bin/sh
mkdir -p $(pwd)/mp4Downloads
ln -s $(pwd)/m4a /var/www/html/m4a
ln -s $(pwd)/mp4Downloads /var/www/html/downloads

/usr/bin/redis-server /etc/redis/redis.conf &
sleep 1
./redis2file.sh &

sed -i "s/www-data/root/" /etc/nginx/nginx.conf
cp -f $(pwd)/default /etc/nginx/sites-enabled/default
/usr/sbin/nginx -g 'daemon on; master_process on;' &

./imgtomp4 &
while :; do sleep 1; done;


