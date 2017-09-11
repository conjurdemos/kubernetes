# sudo not required for mac, but is for linux
# builds Ubuntu client w/ conjur CLI installed but not initialized
DOCKER="docker"
$DOCKER build -t conjur-cli:local -f Dockerfile .
