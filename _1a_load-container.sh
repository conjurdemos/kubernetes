#!/bin/bash -e

set -o pipefail

# Assumptions:
# - docker, minikube and kubectl are already installed


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
}

##############################
##############################
startup_env() {
				# conjur cluster needs at least 4GB
	minikube config set memory 6144
	minikube_status=$(minikube status | awk '/minikube/ {print $2}') 
	if [[ "$minikube_status" == "Stopped" ]]; then
		minikube start 
	fi
	# use the minikube docker environment
	eval $(minikube docker-env)
}

##############################
# load appliance and tag as conjur-appliance:4.9-stable
load_tag_conjur_image() {
# To load the latest Conjur 4.9 appliance from the Conjur docker hub,
# (requires internet access):
#	$DOCKER pull registry2.itci.conjur.net/conjur-appliance:4.9-stable
#	$DOCKER tag registry2.itci.conjur.net/conjur-appliance:4.9-stable conjur-appliance:4.9-stable
	CONJUR_APPLIANCE_TAR=~/conjur-install-images/conjur-appliance-4.9.4.0.tar 

	$DOCKER load -i $CONJUR_APPLIANCE_TAR
	IMAGE_NAME=$($DOCKER images | awk '/registry.tld/ { print $1":"$2; exit}')
	$DOCKER tag $IMAGE_NAME conjur-appliance:4.9-stable
}

main $@
