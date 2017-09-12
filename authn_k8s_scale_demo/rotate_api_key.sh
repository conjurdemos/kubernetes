#!/bin/bash -e
set -o pipefail
conjur authn logout
conjur authn login
export CLIENT_API_KEY=$(conjur host rotate_api_key -h conjur/authn-k8s/minikube/default/client)
echo Client API key: $CLIENT_API_KEY
			# save client API key as k8s secret
#kubectl delete secret conjur-client-api-key
#kubectl create secret generic conjur-client-api-key --from-literal "api-key=$CLIENT_API_KEY"
