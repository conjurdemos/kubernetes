#!/bin/bash -e
set -o pipefail
eval $(minikube docker-env)

main() {
	initialize_conjur
	scope launch		# launch weave scope
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

main $@
