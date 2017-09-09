#!/bin/bash -e
set -o pipefail
eval $(minikube docker-env)

main() {
	initialize_conjur
	build_application_image
	install_weavescope
}

initialize_conjur() {
	rm conjurrc conjur-dev.pem
	conjur init -h conjur-master -f conjurrc << END
yes
END
	export CONJURRC=$(pwd)/conjurrc
	#conjur plugin install policy
	conjur authn login -u admin -p Cyberark1
	# create secadmin user, password is foo
	conjur bootstrap << END

yes
secadmin
foo
foo
yes
END
}

build_application_image() {
	cd build
	./build.sh
	cd ..
}

install_weavescope() {
	# setup weave scope for visualization
	weave_image=$(docker images | awk '/weave/ {print $1}')
	if [[ "$weave_image" == "" ]]; then
		sudo curl -L git.io/scope -o /usr/local/bin/scope
		sudo chmod a+x /usr/local/bin/scope
	scope launch
	fi
}

main $@
