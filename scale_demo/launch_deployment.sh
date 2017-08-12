#!/bin/bash

# get pointers to Conjur api and SSL certificate
source EDIT.ME
if [[ "$CONJUR_APPLIANCE_URL" = "" ]] ; then
	printf "\n\nEdit file EDIT.ME to set your appliance URL and certificate path.\n\n"
	exit 1
fi

# global variables
declare HOST_API_KEY
declare HOST_SESSION_TOKEN
declare SECRET_VALUE
declare URLIFIED

declare DEBUG_BREAKPT=""
#declare DEBUG_BREAKPT="read -n 1 -s -p 'Press any key to continue'"

################  MAIN   ################
# $1 - name of deployment

main() {
	if [[ $# -ne 1 ]] ; then
		printf "\n\tUsage: %s <deployment-name>\n\n" $0
		exit 1
	fi
	local deployment_name=$1

	config_name="$deployment_name".config
	local config_data="$(kubectl get configmap $config_name -o json | jq -r '.data')"
	local hf_name=$(echo $config_data | jq -r '.hf_name')
	local hf_token=$(echo $config_data | jq -r '.hf_token')
	local var_id=$(echo $config_data | jq -r '.var_name')
	local sleep_time=$(echo $config_data | jq -r '.sleep_time')

	printf "\n\nIn deployer process:\n"
	printf "\tDeployment name: %s\n" $deployment_name 
	printf "\tHF name: %s\n" $hf_name 
	printf "\tHF token: %s\n" $hf_token 
	urlify $var_id
	var_id=$URLIFIED
	printf "\tVariable ID: %s\n" $var_id
	printf "\tSleep time: %s\n" $sleep_time
	echo ""
	read -n 1 -s -p "Press any key to continue..."

	# use HF token to register host, get API key
	HOST_API_KEY=$(curl -s \
          --cacert $CONJUR_CERT_FILE \
       	  --request POST \
       	  -H "Content-Type: application/json" \
       	  -H "Authorization: Token token=\"$hf_token\"" \
       	  $CONJUR_APPLIANCE_URL/host_factories/hosts?id=$deployment_name \
       	  | jq -r '.api_key')

	if [[ "$HOST_API_KEY" == "" ]]; then
		echo "No API key - perhaps host factory token expired?"
	else
		echo "Redeemed HF token for API key" $HOST_API_KEY 
	fi

        $(kubectl delete configmap $deployment_name) >> /dev/null     # delete configmap if it exists
        # write out endpoint, access token, variable name and sleep time
        kubectl create configmap $deployment_name \
                --from-literal=conjur-service-url=https://conjur-master/api \
                --from-literal=deployment-name=$deployment_name \
                --from-literal=api-key=$HOST_API_KEY \
                --from-literal=var-name=$var_id \
                --from-literal=sleep-time=$sleep_time

        kubectl get configmap $deployment_name -o yaml	# echo config parameters

	kubectl create -f $deployment_name.yaml		# launch deployment
}
 
################
# REGISTER HOST to the associated layer using the host factory token 
#    Note that if the host already exists, this command will create a new API key for it 
# $1 - application name

hf_register_host() {
	local hf_token=$1; shift
	local host_name=$1; shift

	HOST_API_KEY=$( curl \
	 -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
     	 -H "Content-Type: application/json" \
	 -H "Authorization: Token token=\"$hf_token\"" \
	 $CONJUR_APPLIANCE_URL/host_factories/hosts?id=$host_name \
	 | jq -r '.api_key')

}

################
# HOST AUTHN using its name and API key to get session token
# $1 - host name 
# $2 - API key
host_authn() {
	local host_name=$1; shift
	local host_api_key=$1; shift

	urlify $host_name
	local host_name_urlfmt=host%2F$URLIFIED		# authn requires host/ prefix

	# Authenticate host w/ its name & API key to get session token
	 response=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
	 --data-binary $host_api_key \
	 $CONJUR_APPLIANCE_URL/authn/users/{$host_name_urlfmt}/authenticate)

	 HOST_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')
}

# URLIFY - converts '/' and ':' in input string to hex equivalents
# in: $1 - string to convert
# out: URLIFIED - converted string in global variable
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        URLIFIED=$str
}

# LIST RESOURCES accessible to application
# in: host_name
list_resources() {
	local host_name=$1; shift

	curl -s \
	 --cacert $CONJUR_CERT_FILE \
        -H "Content-Type: application/json" \
        -H "Authorization: Token token=\"$HOST_SESSION_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/authz/{$host_name}/resources/variable
}

main "$@"
