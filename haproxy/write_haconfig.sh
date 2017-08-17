#!/bin/bash -ex
#
# Copies the file /root/haproxy_template to ./haproxy.cfg and then appends
# the server entries for all conjur-appliance pods.
# Pod names & IP addresses are obtained via kubectl.

cp /root/haproxy_template haproxy.cfg

pod_list=$(kubectl get pods -lapp=conjur-appliance | awk '/conjur-master/ {print $1}')
for pod_name in $pod_list; do
	pod_ip=$(kubectl describe pod $pod_name | awk '/IP:/ {print $2}')
	echo -e '\t' server $pod_name $pod_ip:443 check >> haproxy.cfg
done

exit 0
