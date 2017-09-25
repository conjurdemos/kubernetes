#!/bin/bash -e
set -o pipefail
kubectl config use-context minikube

eval $(minikube docker-env)

main() {
	initialize_conjur
	initialize_users
	build_app
	scope launch		# launch weave scope

	conjur authn logout
	echo "Now, you should run the following command in your terminal:"
	echo "export CONJURRC=$CONJURRC"
}

initialize_conjur() {
	rm -f conjurrc conjur-dev.pem
	conjur init -h conjur-master -f conjurrc << END
yes
END
	export CONJURRC=$(pwd)/conjurrc
	#conjur plugin install policy
	conjur authn login -u admin -p Cyberark1
	conjur bootstrap
}

initialize_users() {
	# create demo users, all passwords are foo
	conjur policy load --as-group=security_admin policy/users-policy.yml | tee up-out.json
	ted_pwd=$(cat up-out.json | jq -r '."dev:user:ted"')
	bob_pwd=$(cat up-out.json | jq -r '."dev:user:bob"')
	alice_pwd=$(cat up-out.json | jq -r '."dev:user:alice"')
	carol_pwd=$(cat up-out.json | jq -r '."dev:user:carol"')
	rm up-out.json
	conjur authn login -u ted -p $ted_pwd
	echo "Teds password is foo"
	conjur user update_password << END
foo
foo
END
	conjur authn login -u bob -p $bob_pwd
	echo "Bobs password is foo"
	conjur user update_password << END
foo
foo
END
	conjur authn login -u alice -p $alice_pwd
	echo "Alice password is foo"
	conjur user update_password << END
foo
foo
END
	conjur authn login -u carol -p $carol_pwd
	echo "Carols password is foo"
	conjur user update_password << END
foo
foo
END
}

build_app() {
	cd build
	./build.sh
	cd ..
}

main $@
