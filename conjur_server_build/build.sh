if "$(ls *.deb)" == "" ]]; then
	echo
	echo "You need to build the authn-k8s.deb file and put it in this directory."
	echo "See https://github.com/conjurinc/authn-k8s"
	echo
fi
# builds Ubuntu client w/ conjur CLI installed but not initialized
docker build -t conjur-appliance:local -f Dockerfile .
