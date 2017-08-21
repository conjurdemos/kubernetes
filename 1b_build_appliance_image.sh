#!/bin/bash -e

set -o pipefail

# Assumptions:
# - conjur-appliance:4.9-stable exists in the Minikube Docker engine.
# - You have the artifact "conjur-authn-k8s_${AUTHN_K8S_VERSION}_amd64.deb" in the conjur_server_build directory.

pushd ./conjur_server_build
./build.sh
popd

# builds haproxy image with startup scripts
pushd ./haproxy
./build.sh
popd
