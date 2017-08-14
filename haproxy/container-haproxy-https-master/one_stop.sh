#!/bin/bash

eval $(docker-machine env default)
docker ps | grep haproxy-simple-nginx | tail -1 | awk '{print $1}' | xargs -I {} docker stop {}
