#!/bin/bash -x
# Assumptions:
# - Conjur service is already configured and running in a pod

##############################
##############################
# MAIN - takes no command line arguments

main() {
	build_conjur_client
	startup_conjur_client
	configure_conjur_client
	initialize_conjur_client
}

##############################
##############################

##############################
# build client image
build_conjur_client() {
	pushd build
	./build.sh
	popd
}

##############################
# startup client as defined in yaml file
startup_conjur_client() {
				# start up conjur-client container
	kubectl create -f conjur-client.yaml
	sleep 5
}

##############################
# configure client network connect to conjur master
configure_conjur_client() {
				# get conjur service IP
        CLUSTER_IP=$(kubectl describe svc conjur-service | awk '/IP:/ { print $2; exit}')
	kubectl exec conjur-client -- /bin/bash -c "printf \"%s\t%s\n\" $CLUSTER_IP conjur-service >> /etc/hosts"
	kubectl exec conjur-client -- /bin/bash -c "curl -k https://conjur-service/health"
}
##############################
# initialize client cli
initialize_conjur_client() {
	printf "Run conjur init manually now...\n"
	kubectl exec -it conjur-client -- /bin/bash
}

main $@
