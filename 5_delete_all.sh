#!/bin/bash

declare CONJUR_NAMESPACE=conjur

kubectl config use-context minikube

kubectl delete --ignore-not-found=true -f ./authn_k8s_scale_demo/webapp.yaml
kubectl delete replicaset -lapp=webapp
kubectl delete pods -lapp=webapp

kubectl delete pods --ignore-not-found=true conjur-cli
kubectl delete --ignore-not-found=true configmap cli-conjur

kubectl delete namespace $CONJUR_NAMESPACE

rm ./conjur-service/*.tar
