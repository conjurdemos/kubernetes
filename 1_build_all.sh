#!/bin/bash -e
set -o pipefail

# after running this, the demo will run w/o internet access

eval $(minikube docker-env)

main() {
	load_conjur_image
	tag_conjur_image
	build_appliance_image	# adds authn_k8s service to appliance
	build_haproxy_image
	build_cli_client_image
	build_demo_app_image
	install_weavescope
	./time_sync.sh
}

load_conjur_image() {

# YOU HAVE TWO OPTIONS:

# Option 1: To load the latest Conjur 4.9 appliance from the Conjur docker hub:
#	docker pull registry2.itci.conjur.net/conjur-appliance:4.9-stable
#	docker tag registry2.itci.conjur.net/conjur-appliance:4.9-stable conjur-appliance:4.9-stable

# Option 2: To load the conjur appliance image from a downloaded tarfile, 
#  edit the line below with the path to the tarfile:
	CONJUR_APPLIANCE_TAR=~/conjur-install-images/conjur-appliance-4.9.6.0.tar
	if [[ "$CONJUR_APPLIANCE_TAR" == "" ]]; then
		echo "Edit load_conjur_image() to point to point to set CONJUR_APPLIANCE_TARFILE w/ the path to your conjur-appliance tarfile."
		exit
	fi
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
	pushd ./cli_client/build
	./build.sh
	popd
}

build_demo_app_image() {
        pushd authn_k8s_scale_demo/build
        ./build.sh
        popd
}

install_weavescope() {
        # setup weave scope for visualization
        weave_image=$(docker images | awk '/weave/ {print $1}')
        if [[ "$weave_image" == "" ]]; then
                sudo curl -L git.io/scope -o /usr/local/bin/scope && chmod a+x /usr/local/bin/scope
		scope launch
        fi
}

main $@
