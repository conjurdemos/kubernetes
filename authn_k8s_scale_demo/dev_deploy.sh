#!/bin/bash

source ./evokecmd.sh

kubectl config use-context conjur

echo Grabbing the conjur.pem
ssl_certificate=$(evokecmd cat /opt/conjur/etc/ssl/ca.pem)

kubectl config use-context minikube

echo Storing non-secret configuration data

# write out conjur ssl cert in configmap
kubectl delete --ignore-not-found=true configmap webapp
kubectl create configmap webapp \
  --from-literal=ssl_certificate="$ssl_certificate"

export CLIENT_API_KEY=$(conjur host rotate_api_key -h conjur/authn-k8s/minikube/default/client)
echo Environment token: $CLIENT_API_KEY

# save client API key as k8s secret
kubectl delete --ignore-not-found=true secret conjur-client-api-key
kubectl create secret generic conjur-client-api-key --from-literal "api-key=$CLIENT_API_KEY"

kubectl create -f webapp_dev.yaml
