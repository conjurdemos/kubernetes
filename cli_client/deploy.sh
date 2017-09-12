#!/bin/bash -e

source ./evokecmd.sh

kubectl config use-context conjur

echo Grabbing the conjur.pem
ssl_certificate=$(evokecmd cat /opt/conjur/etc/ssl/ca.pem)

kubectl config use-context minikube

echo Storing non-secret configuration data

# write out conjur ssl cert in configmap
kubectl delete --ignore-not-found=true configmap cli-conjur
kubectl create configmap cli-conjur \
  --from-literal=ssl_certificate="$ssl_certificate"

kubectl create -f cli-conjur.yaml
