#!/bin/bash
conjur authn logout >> /dev/null
conjur authn login 
./load_policy.sh authn_k8s.yml
./load_policy.sh k8s_apps.yml
conjur authn logout >> /dev/null
