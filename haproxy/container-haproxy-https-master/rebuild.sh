#!/bin/bash

echo "Stopping..."
./stop.sh
echo "Done."


./gen_certs.sh

HAPROXYFILE="haproxy/haproxy.cfg"
rm $HAPROXYFILE

echo "Generating HAproxy configuration."
cat > $HAPROXYFILE <<-EOF
$(egrep -v "^server" haproxy/haproxy.cfg.default | egrep -v "^backend")

backend servers
    server server1 $(cat docker_ip.cfg):8000 maxconn 32 check inter 1s rise 1 fall 1
    server server2 $(cat docker_ip.cfg):8001 maxconn 32 check inter 1s rise 1 fall 1

backend servershttps
	# config works because of https://www.digitalocean.com/community/tutorials/how-to-use-haproxy-as-a-layer-4-load-balancer-for-wordpress-application-servers-on-ubuntu-14-04#haproxy-configuration
	balance roundrobin
	mode tcp
    server server3 $(cat docker_ip.cfg):8010 maxconn 32 check inter 1s rise 1 fall 1
    server server4 $(cat docker_ip.cfg):8011 maxconn 32 check inter 1s rise 1 fall 1

EOF

echo "Done generating HAProxy configuration."

RUNCMD="docker run -it --rm --name haproxy-https-haproxy -v $(pwd)/ssl/certHA:/etc/ssl:ro -v $(pwd)/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg haproxy"

echo ""
echo "Testing HAProxy configuration..."
CMD="haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg"
$RUNCMD $CMD

echo ""
echo "Testing NGINX configuration..."
docker run -it --rm --name haproxy-https-nginx-test -v $(pwd)/www/conf_d-default.conf:/etc/nginx/conf.d/default.conf:ro -v $(pwd)/www/nginx.conf:/etc/nginx/nginx.conf:ro -v $(pwd)/ssl/2:/etc/ssl:ro -v $(pwd)/www/2:/usr/share/nginx/html:ro nginx /usr/sbin/nginx -t

echo ""
echo "Done."
