# sudo not required for mac, but is for linux
# builds Ubuntu client w/ conjur CLI installed but not initialized
DOCKER="docker"
if [[ "$(uname -s)" == "Linux" ]]; then
        DOCKER="sudo docker"
fi

$DOCKER build -t conjur-appliance:local -f Dockerfile .
