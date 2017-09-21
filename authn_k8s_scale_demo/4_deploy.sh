#!/bin/bash -e

source ./conjurcmd.sh

kubectl config use-context conjur

echo Grabbing the conjur.pem
ssl_certificate=$(conjurcmd cat /opt/conjur/etc/ssl/ca.pem)

kubectl config use-context minikube

echo Storing non-secret configuration data

# write out conjur ssl cert in configmap
kubectl delete --ignore-not-found=true configmap webapp
kubectl create configmap webapp \
  --from-literal=ssl_certificate="$ssl_certificate"

kubectl create -f webapp.yaml
kubectl create -f webapp-summon.yaml
