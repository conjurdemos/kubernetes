#!/bin/bash
conjur authn logout
./load_policy.sh webapp.yml
conjur authn logout
