#!/bin/bash
./load_policy.sh authn_k8s.yml
./load_policy.sh k8s_apps.yml

source ./conjurcmd.sh

kubectl config use-context conjur

webservice=conjur/authn-k8s/minikube/default
echo "Initializing the CA certificate and key for webservice:$webservice"
conjurcmd conjur-plugin-service authn-k8s rake ca:initialize[$webservice]
