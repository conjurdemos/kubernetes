#!/bin/bash -e

set -o pipefail

# Assumptions:
# - docker, minikube and kubectl are already installed

DOCKER=docker

eval $(minikube docker-env)

# YOU HAVE TWO OPTIONS:

# Option 1: To load the latest Conjur 4.9 appliance from the Conjur docker hub,
# (requires internet access):
#	$DOCKER pull registry2.itci.conjur.net/conjur-appliance:4.9-stable
#	$DOCKER tag registry2.itci.conjur.net/conjur-appliance:4.9-stable conjur-appliance:4.9-stable

# Option 2: To load the conjur appliance image from a local tarfile, 
#  edit the line below with the path to the tarfile:
CONJUR_APPLIANCE_TAR=/Users/josephhunt/conjur-install-images/conjur-appliance-4.9.4.0.tar
$DOCKER load -i $CONJUR_APPLIANCE_TAR
IMAGE_NAME=$($DOCKER images | awk '/registry.tld/ { print $1":"$2; exit}')
$DOCKER tag $IMAGE_NAME conjur-appliance:4.9-stable
