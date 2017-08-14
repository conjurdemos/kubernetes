#!/bin/bash

source ./evokecmd.sh

echo Grabbing the conjur.pem
ssl_certificate=$(evokecmd cat /opt/conjur/etc/ssl/ca.pem)

echo Storing non-secret configuration data

# write out host factory name & token, variable name and deployment name in configmap
kubectl delete configmap webapp
kubectl create configmap webapp \
  --from-literal=ssl_certificate="$ssl_certificate"

#export CLIENT_API_KEY=$(conjur host rotate_api_key -h conjur/authn-k8s/minikube/default/client)
export CLIENT_API_KEY=1dxfntm2hgxct51q91h0y1dhxpxg2b4reve26mbn2zxj1dma1yqht6y # $(conjur host rotate_api_key -h conjur/authn-k8s/minikube/default/client)
echo Client API key: $CLIENT_API_KEY

kubectl delete secret conjur-client-api-key
kubectl create secret generic conjur-client-api-key --from-literal "api-key=$CLIENT_API_KEY"

kubectl create -f webapp.yaml
