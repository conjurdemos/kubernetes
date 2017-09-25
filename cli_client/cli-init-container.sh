#!/bin/bash 
# Assumptions:
# - conjur-service is already configured and running

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
	kubectl create -f cli-conjur.yaml
	sleep 5
}

##############################
# configure client network connect to conjur master
configure_conjur_client() {
				# get conjur service IP
        CLUSTER_IP=$(kubectl describe svc conjur-master | awk '/IP:/ { print $2; exit}')
	kubectl exec conjur-cli -- /bin/bash -c "curl -k https://conjur-master/health"
}
##############################
# initialize client cli
initialize_conjur_client() {
	kubectl exec -it conjur-cli conjur init -h conjur-service -a dev
	printf "\nYou are now in the Conjur CLI container.\n"
	printf "The Conjur CLI, kubectl, docker, curl and jq are all here.\n\n"
	kubectl exec -it conjur-cli -- /bin/bash
}

main $@
