#!/bin/bash -e
set -o pipefail

eval $(minikube docker-env)

main() {
	load_conjur_image
	tag_conjur_image
	build_appliance_image
	build_haproxy_image
	build_cli_client_image
}

load_conjur_image() {

# YOU HAVE TWO OPTIONS:

# Option 1: To load the latest Conjur 4.9 appliance from the Conjur docker hub:
#	docker pull registry2.itci.conjur.net/conjur-appliance:4.9-stable
#	docker tag registry2.itci.conjur.net/conjur-appliance:4.9-stable conjur-appliance:4.9-stable

# Option 2: To load the conjur appliance image from a local tarfile, 
#  edit the line below with the path to the tarfile:
	CONJUR_APPLIANCE_TAR=/home/demo/mydir/conjur-install-images/conjur-appliance-4.9.6.0.tar
	docker load -i $CONJUR_APPLIANCE_TAR
}

tag_conjur_image() {
			# tags image regardless if it was loaded or pulled
	IMAGE_NAME=$(docker images | awk '/registry/ { print $1":"$2; exit}')
	docker tag $IMAGE_NAME conjur-appliance:4.9-stable
}

build_appliance_image() {
# Assumptions:
# - conjur-appliance:4.9-stable exists in the Minikube Docker engine.
# - You have the artifact "conjur-authn-k8s_${AUTHN_K8S_VERSION}_amd64.deb" in the conjur_server_build directory.

	pushd ./conjur_server_build
	./build.sh
	popd
}

build_haproxy_image() {
	pushd ./haproxy
	./build.sh
	popd
}

build_cli_client_image() {
	pushd ./cli_client/cli_image_build
	./build.sh
	popd
}

main $@
