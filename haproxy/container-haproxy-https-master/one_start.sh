#!/bin/bash

eval $(docker-machine env default)
docker ps -a | grep Exited | awk '{print $1}' | xargs -I {} docker start {}
