# sudo not required for mac, but is for linux
DOCKER="docker"
if [[ "$(uname -s)" == "Linux" ]]; then
        DOCKER="sudo docker"
fi

# runs built container image and logs into w/ a bash shell for debugging
$DOCKER run -dit --name foobar cdemo/curl
$DOCKER exec -it foobar /bin/bash
