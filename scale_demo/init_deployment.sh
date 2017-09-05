#!/bin/bash -e
set -o pipefail

# this script:
# - pulls the HF name and token from a configmap
# - redeems HF token for API key
# - echos API key for external use

# get pointers to Conjur api and SSL certificate
source EDIT.ME
if [[ "$CONJUR_APPLIANCE_URL" = "" ]] ; then
	printf "\n\nEdit file EDIT.ME to set your appliance URL and certificate path.\n\n"
	exit 1
fi

# global variables
declare CONJUR_MASTER_URL=$CONJUR_APPLIANCE_URL
declare HOST_API_KEY

declare DEBUG_BREAKPT=""
#declare DEBUG_BREAKPT="read -n 1 -s -p 'Press any key to continue'"

################  MAIN   ################
# $1 - name of deployment

main() {
	if [[ $# -ne 1 ]] ; then
		printf "\n\tUsage: %s <deployment-name>\n\n" $0
		exit -1
	fi
	local deployment_name=$1

	local config_data="$(kubectl get configmap $deployment_name -o json | jq -r '.data')"
	local hf_name=$(echo $config_data | jq -r '.hf_name')
	local hf_token=$(echo $config_data | jq -r '.hf_token')

#	echo_input					# for debugging

	# use HF token to register host, get API key
	HOST_API_KEY=$(curl -s \
          --cacert $CONJUR_CERT_FILE \
       	  --request POST \
       	  -H "Content-Type: application/json" \
       	  -H "Authorization: Token token=\"$hf_token\"" \
       	  $CONJUR_MASTER_URL/host_factories/hosts?id=$deployment_name \
       	  | jq -r '.api_key')

	if [[ "$HOST_API_KEY" == "" ]]; then
		exit -1
	fi

	echo $HOST_API_KEY
}
 
main "$@"
