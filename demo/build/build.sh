# sudo not required for mac, but is for linux
DOCKER="docker"
if [[ "$(uname -s)" == "Linux" ]]; then
        DOCKER="sudo docker"
fi

$DOCKER load -i ./alpine.tar
$DOCKER build -t cdemo/curl:local .
