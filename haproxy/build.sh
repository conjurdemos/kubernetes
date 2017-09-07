# sudo not required for mac, but is for linux
DOCKER="docker"
$DOCKER build -f Dockerfile.haproxy -t haproxy:conjur .
