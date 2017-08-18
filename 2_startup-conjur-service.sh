#!/bin/bash -e

set -o pipefail

# Assumptions:
# - minikube and kubectl are already installed

				# directory of yaml
declare CONFIG_DIR=./conjur-service
				# initially, master is always pod 0
declare MASTER_POD_NAME=conjur-master-0
declare ROOT_KEY=Cyberark1
declare CONJUR_CLUSTER_ACCT=dev
declare CONJUR_MASTER_DNS_NAME=conjur-master

##############################
##############################
# MAIN - takes no command line arguments

main() {
	startup_env
	startup_conjur_service
	configure_conjur_cluster
	start_load_balancer
}

##############################
##############################

##############################
# STEP 1 - startup environment
startup_env() {
	# use the minikube docker environment
	eval $(minikube docker-env)
}

##############################
# STEP 2 - start service 
startup_conjur_service() {
	# start up conjur services from yaml
	kubectl create -f $CONFIG_DIR/conjur-master-headless.yaml

	# give containers time to get running
	echo "Waiting for conjur-master-0 to launch"
  while [[ $(kubectl exec conjur-master-0 evoke role) != "blank" ]]; do
  	echo -n '.'
  	sleep 5
  done
  echo "done"
}

##############################
# STEP 3 - configure cluster based on role labels
# 

configure_conjur_cluster() {
	# label pod with role
	kubectl label --overwrite pod $MASTER_POD_NAME role=master
	# configure Conjur master server using evoke
	kubectl exec $MASTER_POD_NAME -- evoke configure master -j /etc/conjur.json -h $CONJUR_MASTER_DNS_NAME -p $ROOT_KEY $CONJUR_CLUSTER_ACCT

	# prepare seed files for standbys and followers
  kubectl exec $MASTER_POD_NAME evoke seed standby > $CONFIG_DIR/standby-seed.tar
  kubectl exec $MASTER_POD_NAME evoke seed follower conjur-follower > $CONFIG_DIR/follower-seed.tar

	# get master IP address for standby config
	MASTER_POD_IP=$(kubectl describe pod $MASTER_POD_NAME | awk '/IP:/ {print $2}')

	# get list of the other pods 
	pod_list=$(kubectl get pods -lrole=unset \
			| awk '/conjur-master/ {print $1}')
	for pod_name in $pod_list; do
		# label pod with role
		kubectl label --overwrite pod $pod_name role=standby
		# configure standby
		kubectl cp $CONFIG_DIR/standby-seed.tar $pod_name:/tmp/standby-seed.tar
		kubectl exec $pod_name evoke unpack seed /tmp/standby-seed.tar
		kubectl exec $pod_name -- evoke configure standby -j /etc/conjur.json -i $MASTER_POD_IP
	done

	# enable sync replication to designated sync standby
  kubectl exec $MASTER_POD_NAME -- bash -c "evoke replication sync"
}

##########################
# START_LOAD_BALANCER
#

start_load_balancer() {
	# start up load balancer
	kubectl create -f $CONFIG_DIR/haproxy-conjur-master.yaml

	# get internal/external IP addresses
	CLUSTER_IP=$(kubectl describe svc conjur-master | awk '/IP:/ { print $2; exit}')
	EXTERNAL_IP=$(kubectl describe svc conjur-master | awk '/External IPs:/ { print $3; exit}')

	# inform user of IP addresses 
	printf "\n\nIn conjur-client container, add:\n\t%s\tconjur-master\n to /etc/hosts.\n\n" $CLUSTER_IP 
	printf "\n\nOutside the cluster, add:\n\t%s\tconjur-master\n to /etc/hosts.\n\n" $EXTERNAL_IP 
}

main $@
