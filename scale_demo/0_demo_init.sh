#!/bin/bash -x
conjur init -h conjur-master -f conjurrc
export CONJURRC=$(pwd)/conjurrc
conjur authn login -u admin -p Cyberark1

# create secadmin user, password is foo
conjur bootstrap << END
yes
secadmin
foo
foo
yes
END

# create demo users, passwords are foo
conjur policy load --as-group=security_admin users-policy.yml | tee up-out.json
bob_pwd=$(cat up-out.json | jq -r '."dev:user:bob"')
carol_pwd=$(cat up-out.json | jq -r '."dev:user:carol"')
rm up-out.json
conjur authn login -u carol -p $carol_pwd
echo "Carols password is foo"
conjur user update_password << END
foo
foo
END
conjur authn login -u bob -p $bob_pwd 
echo "Create new password for Bob..."
conjur user update_password << END
foo
foo
END

# setup weave scope for visualization
weave_image=$(docker images | awk '/weave/ {print $1}')
if [[ "$weave_image" == "" ]]; then
	sudo curl -L git.io/scope -o /usr/local/bin/scope
	sudo chmod a+x /usr/local/bin/scope
	scope launch
fi

# build webapp1 image
cd build
./build.sh
sleep 3
cd ..

# set mount directory to current
cat template.webapp1.yaml | sed "s={{demo-dir}}=$PWD=g" > webapp1.yaml
