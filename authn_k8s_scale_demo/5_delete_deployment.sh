#!/bin/bash

kubectl config use-context minikube

kubectl delete -f webapp.yaml
