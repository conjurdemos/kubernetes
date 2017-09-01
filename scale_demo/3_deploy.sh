#!/bin/bash -x
echo $(./init_deployment.sh webapp1) > api_key
kubectl create -f webapp1.yaml
sleep 5
rm api_key
