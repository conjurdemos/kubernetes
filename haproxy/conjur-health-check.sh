#!/bin/bash

exit 0

proxy_address=$1
proxy_port=$2
server_address=$3
server_port=$4

echo "server_address: " $server_address

conjur_ok=$(curl -k https://172.17.0.2/health | jq '.ok')
if [[ "$conjur_ok" == "true" ]]; then
	echo "Conjur is OK"
	exit 0
fi
echo "Conjur is NOT OK"
exit -1
