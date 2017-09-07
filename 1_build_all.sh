#!/bin/bash -e
set -o pipefail

eval $(minikube docker-env)
./_1a_load-container.sh
./_1b_build_appliance_image.sh
./_1c_build_haproxy_image.sh
./_1d_build_cli_client.sh
