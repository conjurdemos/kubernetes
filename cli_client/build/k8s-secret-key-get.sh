#!/bin/bash -e
# assumes $1 is in form: secret:key
set -o pipefail
secret=$(echo $1 | cut -d':' -f 1)
key=$(echo $1 | cut -d':' -f 2)
printf -v key "\"%s\"" $key
value=$(kubectl get secret $secret -o json | jq -r ".data | .$key")
if [[ "$value" != "" ]]; then
	echo $value | base64 --decode
	exit 0
fi
exit -1
