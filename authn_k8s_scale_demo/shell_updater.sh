#!/bin/bash 
set -o pipefail
conjur authn logout
conjur authn login
while [[ 1 == 1 ]]; do
	new_pwd=$(openssl rand -hex 12)
	error_msg=$(conjur variable values add db/password $new_pwd 2>&1 >/dev/null)
	if [[ "$error_msg" = "" ]]; then
		echo $(date +%X) "New db password is:" $new_pwd
	else
		echo $error_msg
	fi
	sleep 5
done
