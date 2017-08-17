#!/bin/bash

kubectl delete -f ./conjur-service
kubectl delete pods -lapp=conjur-appliance
rm ./conjur-service/*.tar
