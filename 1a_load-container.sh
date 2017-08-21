#!/bin/bash -e

set -o pipefail

# Assumptions:
# - docker, minikube and kubectl are already installed

# This script loads the Conjur appliance from TAR into the Minikube Docker Engine.
# You can accomplish the same thing (faster) like this:
# 
# $ eval $(minikube docker-env)
# $ docker pull registry2.itci.conjur.net/conjur-appliance:4.9-stable
# $ docker tag registry2.itci.conjur.net/conjur-appliance:4.9-stable conjur-appliance:4.9-stable

declare CONJUR_APPLIANCE_TAR=~/conjur-install-images/conjur-appliance-4.9.4.0.tar

# sudo not required for mac, but is for linux
DOCKER="docker"
if [[ "$(uname -s)" == "Linux" ]]; then
	DOCKER="sudo docker"
fi

##############################
##############################
# MAIN - takes no command line arguments

main() {
	startup_env
	load_tag_conjur_image
	build_conjur_authnk8s_image
	build_conjur_cli_image
	build_haproxy_image
}

##############################
##############################
startup_env() {
	minikube_status=$(minikube status | awk '/minikube/ {print $2}') 
	if [[ "$minikube_status" == "Stopped" ]]; then
		minikube start
	fi
	# use the minikube docker environment
	eval $(minikube docker-env)
}

##############################
# load appliance and tag as conjur-appliance:local
load_tag_conjur_image() {
	$DOCKER load -i $CONJUR_APPLIANCE_TAR
	CONTAINER_NAME=$($DOCKER images | awk '/registry.tld/ { print $1":"$2; exit}')

	# use 'local' tag to prevent kubectl from trying to pull latest
	$DOCKER tag $CONTAINER_NAME conjur-appliance:4.9-stable
}

##############################
build_conjur_authnk8s_image() {
	pushd ./conjur_server_build
	./build.sh
	popd
}

##############################
build_haproxy_image() {
	pushd ./haproxy
	./build.sh
	popd
}

##############################
build_conjur_cli_image() {
	pushd ./cli_client/cli_image_build
	./build.sh
	popd
}

main $@
