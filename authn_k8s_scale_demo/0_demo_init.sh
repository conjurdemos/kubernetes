#!/bin/bash -e
set -o pipefail
conjur init -h conjur-master -f conjurrc
export CONJURRC=$(pwd)/conjurrc
printf "Login with password 'Cyberark1'...\n"
conjur plugin install policy
conjur authn login admin
conjur bootstrap
cd build
./build.sh
cd ..
