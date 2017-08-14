#!/bin/bash
echo "Targeting the following nodes:"
docker ps -f name=haproxy-https-

echo ""
echo "Stopping now..."
docker ps -qa -f name=haproxy-https- | xargs docker rm -f
echo "Done."
