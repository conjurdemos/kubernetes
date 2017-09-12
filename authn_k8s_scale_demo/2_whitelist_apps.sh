#!/bin/bash
conjur authn logout
./load_policy.sh k8s_apps.yml
conjur authn logout
