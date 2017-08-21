#!/bin/bash

# Delete all stopped containers
docker rm $( docker ps -q -f status=exited)
docker rm $( docker ps -q -f status=dead)
# Delete all dangling (unused) images
docker rmi $( docker images -q -f dangling=true)
