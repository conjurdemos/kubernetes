#!/bin/bash -ex

cd /usr/local/etc/haproxy/

/root/pg_servers.sh
/root/http_servers.sh

exec haproxy -d -f ./haproxy.cfg -f ./http_servers.cfg -f ./pg_servers.cfg
