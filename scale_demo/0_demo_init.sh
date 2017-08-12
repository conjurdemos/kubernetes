#!/bin/bash -x
conjur init -h conjur-master -f conjurrc
export CONJURRC=$(pwd)/conjurrc
printf "Login with password 'Cyberark1'...\n"
conjur authn login admin
conjur policy load --as-group=security_admin users-policy.yml | tee up-out.json
bob_pwd=$(cat up-out.json | jq -r '."dev:user:bob"')
carol_pwd=$(cat up-out.json | jq -r '."dev:user:carol"')
rm up-out.json
conjur authn login -u carol -p $carol_pwd
echo "Create new password for Carol..."
conjur user update_password
conjur authn login -u bob -p $bob_pwd 
echo "Create new password for Bob..."
conjur user update_password
# setup weave scope for visualization
weave_image=$(docker images | awk '/weave/ {print $1}')
if [[ "$weave_image" == "" ]]; then
	sudo curl -L git.io/scope -o /usr/local/bin/scope
	sudo chmod a+x /usr/local/bin/scope
	scope launch
fi
cd build
./build.sh
cd ..
