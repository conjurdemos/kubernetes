#!/bin/bash -e

set -o pipefail

# Assumptions:
# - minikube and kubectl are already installed

# directory of yaml
declare CONFIG_DIR=./conjur-service
# initially, master is always pod 0
declare MASTER_POD_NAME=conjur-master-0
declare ADMIN_PASSWORD=Cyberark1
declare CONJUR_CLUSTER_ACCT=dev
declare CONJUR_NAMESPACE=conjur
declare CONJUR_MASTER_DNS_NAME=conjur-master.$CONJUR_NAMESPACE.svc.cluster.local
declare CONJUR_FOLLOWER_DNS_NAME=conjur-follower.$CONJUR_NAMESPACE.svc.cluster.local

##############################
##############################
# MAIN - takes no command line arguments

main() {
	startup_env
	create_namespace
	startup_conjur_service
	configure_conjur_cluster
	start_load_balancer
	startup_client
	print_config
}

##############################
##############################

##############################
# STEP 1 - startup environment
startup_env() {
	# use the minikube docker environment
	eval $(minikube docker-env)
}

create_namespace() {
	if kubectl get namespace | grep -w $CONJUR_NAMESPACE > /dev/null; then
		echo "Conjur namespace '$CONJUR_NAMESPACE' exists. I won't create it."
	else
		kubectl create namespace $CONJUR_NAMESPACE
	fi

	kubectl config set-context conjur --namespace=conjur --cluster=minikube --user=minikube
}

##############################
# STEP 2 - start service 
startup_conjur_service() {
	kubectl config use-context conjur

	# start up conjur services from yaml
	kubectl create -f $CONFIG_DIR/conjur-master-headless.yaml

	# give containers time to get running
	echo "Waiting for conjur-master-0 to launch"
	sleep 5
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
	kubectl config use-context conjur

	# label pod with role
	kubectl label --overwrite pod $MASTER_POD_NAME role=master

	printf "Configuring conjur-master %s...\n" $MASTER_POD_NAME
	# configure Conjur master server using evoke
	kubectl exec $MASTER_POD_NAME -- evoke configure master \
		-j /etc/conjur.json \
		-h $CONJUR_MASTER_DNS_NAME \
		--master-altnames conjur-master \
		--follower-altnames conjur-follower \
		-p $ADMIN_PASSWORD \
		$CONJUR_CLUSTER_ACCT

	printf "Preparing seed files...\n"
	# prepare seed files for standbys and followers
  kubectl exec $MASTER_POD_NAME evoke seed standby > $CONFIG_DIR/standby-seed.tar
  kubectl exec $MASTER_POD_NAME evoke seed follower $CONJUR_FOLLOWER_DNS_NAME > $CONFIG_DIR/follower-seed.tar

	# get master IP address for standby config
	MASTER_POD_IP=$(kubectl describe pod $MASTER_POD_NAME | awk '/IP:/ {print $2}')

	# get list of the other pods 
	pod_list=$(kubectl get pods -lrole=unset \
			| awk '/conjur-master/ {print $1}')
	for pod_name in $pod_list; do
		printf "Configuring standby %s...\n" $pod_name
		# label pod with role
		kubectl label --overwrite pod $pod_name role=standby
		# configure standby
		kubectl cp $CONFIG_DIR/standby-seed.tar $pod_name:/tmp/standby-seed.tar
		kubectl exec $pod_name evoke unpack seed /tmp/standby-seed.tar
		kubectl exec $pod_name -- evoke configure standby -j /etc/conjur.json -i $MASTER_POD_IP
	done

	if [[ "$pod_list" != "" ]]; then
		printf "Starting synchronous replication...\n"
		# enable sync replication to designated sync standby
		kubectl exec $MASTER_POD_NAME -- bash -c "evoke replication sync"
	fi
}

##########################
# START_LOAD_BALANCER
#

start_load_balancer() {
	kubectl config use-context conjur

	# start up load balancer
	kubectl create -f $CONFIG_DIR/haproxy-conjur-master.yaml

	sleep 5
}

startup_client() {
	echo "Starting up the client Pod"

	pushd cli_client
	./deploy.sh
	popd

	kubectl config use-context minikube
}

print_config() {
	# get internal/external IP addresses
	CLUSTER_IP=$(kubectl describe svc conjur-master | awk '/IP:/ { print $2; exit}')
	EXTERNAL_IP=$(kubectl describe svc conjur-master | awk '/External IPs:/ { print $3; exit}')

	# inform user of IP addresses 
	printf "\nInside Kubernetes, you can reach the Conjur master at: conjur-master.%s.svc.cluster.local\n" $CONJUR_NAMESPACE 
	printf "\nOutside the cluster, add this line to /etc/hosts:\n\n\t%s\tconjur-master\n\n" $EXTERNAL_IP 	
}

main $@
