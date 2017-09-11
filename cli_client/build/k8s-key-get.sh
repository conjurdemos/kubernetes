#!/bin/bash -e
set -o pipefail
printf -v key "\"%s\"" $1
secrets_list=$(kubectl get secrets --no-headers | awk '{print $1}')
for i in $secrets_list; do
	secret_data=$(kubectl get secret $i -o json | jq .data)
	found=$(echo $secret_data | jq "has($key)")
	if [[ "$found" == "true" ]]; then
		value=$(echo $secret_data | jq -r .$key)
		echo $value | base64 --decode
		exit
	fi
done
