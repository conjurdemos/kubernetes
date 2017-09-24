#!/bin/bash -e
set -o pipefail

declare CONFIG_DIR=./conjur-service

kubectl config use-context conjur

main() {
	kubectl create -f $CONFIG_DIR/conjur-follower.yaml
	sleep 5		# allow pods to get running

         # get list of follower pods 
        pod_list=$(kubectl get pods -lrole=follower --no-headers | awk '{print $1}')
        for pod_name in $pod_list; do
                printf "Configuring follower %s...\n" $pod_name
                # label pod with role
                kubectl label --overwrite pod $pod_name role=follower
                # configure follower
                kubectl cp $CONFIG_DIR/follower-seed.tar $pod_name:/tmp/follower-seed.tar
                kubectl exec $pod_name evoke unpack seed /tmp/follower-seed.tar
                kubectl exec $pod_name -- evoke configure follower -j /etc/conjur.json 
	done
}

main $@
