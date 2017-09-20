#!/bin/bash

kubectl config use-context minikube

kubectl delete --ignore-not-found=true -f webapp.yaml
kubectl delete --ignore-not-found=true -f webapp-summon.yaml
kubectl delete --ignore-not-found=true configmap webapp
