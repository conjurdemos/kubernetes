#!/bin/bash 
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
	pushd ./conjur_server_build
	./build.sh
	popd
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
# STEP 2 - load appliance and tag as conjur-appliance:local
load_tag_conjur_image() {
	$DOCKER load -i $CONJUR_APPLIANCE_TAR
	CONTAINER_NAME=$($DOCKER images | awk '/registry.tld/ { print $1":"$2; exit}')

	# use 'local' tag to prevent kubectl from trying to pull latest
	$DOCKER tag $CONTAINER_NAME conjur-appliance:4.9-stable
}

main $@
