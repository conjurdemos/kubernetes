#!/bin/bash
conjur authn logout
./load_policy.sh authn_k8s.yml
conjur authn logout
