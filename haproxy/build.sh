# sudo not required for mac, but is for linux
DOCKER="docker"
if [[ "$(uname -s)" == "Linux" ]]; then
        DOCKER="sudo docker"
fi

$DOCKER build -f Dockerfile.haproxy -t haproxy:conjur .
