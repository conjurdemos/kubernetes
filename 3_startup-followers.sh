#!/bin/bash -e

set -o pipefail

# Followers are self-configuring w/ initContainers and postStart lifecycle hooks

declare CONFIG_DIR=./conjur-service

kubectl config use-context conjur

main() {
	pushd $CONFIG_DIR
	cat template.conjur-follower.yaml | sed "s={{seedfile-dir}}=$PWD=g" > conjur-follower.yaml
	popd
	kubectl create -f $CONFIG_DIR/conjur-follower.yaml
}

main $@
