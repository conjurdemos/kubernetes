#!/bin/bash -x
#
# Appends server entries for all conjur-appliance pods to a base
# haproxy configuraton using pod names & IP addresses obtained via kubectl

cp haproxy_template haproxy.cfg
echo "copied template to target file"

pod_list=$(kubectl get pods -lapp=conjur-appliance | awk '/conjur-master/ {print $1}')
for pod_name in $pod_list; do
	pod_ip=$(kubectl describe pod $pod_name | awk '/IP:/ {print $2}')
	echo -e '\t' server $pod_name $pod_ip:443 check >> ./haproxy.cfg
done

exit 0
