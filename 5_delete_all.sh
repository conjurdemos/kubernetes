#!/bin/bash

declare CONJUR_NAMESPACE=conjur

kubectl delete -f ./authn_k8s_scale_demo/webapp.yaml
kubectl delete replicaset -lapp=webapp
kubectl delete pods -lapp=webapp

kubectl delete namespace $CONJUR_NAMESPACE

rm ./conjur-service/*.tar
