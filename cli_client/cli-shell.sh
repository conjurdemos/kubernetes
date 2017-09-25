#!/bin/bash -e
set -o pipefail
		# if cli container not running, start it
if [[ "$(kubectl get pods --no-headers | grep conjur-cli)" == "" ]]; then
	kubectl create -f cli-conjur.yaml
	sleep 3
fi
kubectl exec -it conjur-cli -- bash
