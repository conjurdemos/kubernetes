#!/bin/bash
./load_policy.sh db.yml

password=$(openssl rand -hex 12)

echo "Storing DB password : $password"

conjur authn logout
conjur variable values add db/password $password
conjur authn logout
