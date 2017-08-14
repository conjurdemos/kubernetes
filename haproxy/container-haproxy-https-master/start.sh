#!/bin/bash
./stop.sh

CONFONE="$(pwd)/www/conf_d-default.conf:/etc/nginx/conf.d/default.conf:ro"
CONFTWO="$(pwd)/www/nginx.conf:/etc/nginx/nginx.conf:ro"
HTMLDIR="/usr/share/nginx/html"

HAPORTS="-p 8080:8080 -p 8081:8081 -p 8082:8082"
SSL="/etc/ssl"

echo "Starting nginx containers..."
docker run -d -p 8000:80 -p 8010:443 --name haproxy-https-nginx-1 -v $CONFONE -v $CONFTWO -v $(pwd)/ssl/1:$SSL:ro -v $(pwd)/www/1:$HTMLDIR:ro nginx
docker run -d -p 8001:80 -p 8011:443 --name haproxy-https-nginx-2 -v $CONFONE -v $CONFTWO -v $(pwd)/ssl/2:$SSL:ro -v $(pwd)/www/2:$HTMLDIR:ro nginx
echo "Done."

echo "Starting HAProxy"
docker run -d $HAPORTS --name haproxy-https-haproxy -v $(pwd)/ssl/certHA:$SSL:ro -v $(pwd)/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg haproxy
echo "Done."
