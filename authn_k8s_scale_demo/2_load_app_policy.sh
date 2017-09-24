#!/bin/bash
conjur authn logout >> /dev/null
conjur authn login
./load_policy.sh webapp.yml
conjur authn logout >> /dev/null
