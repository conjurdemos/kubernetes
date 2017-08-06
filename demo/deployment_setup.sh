#!/bin/bash 
#
# Admin_process
# This process simulates the role of a human security administrator who setups up
# a kubernetes deployment for an application. distributes Host Factory tokens 
#
# Usage: admin_process <host-factory-name> <variable-to-fetch> <deployment-name>

################  MAIN   ################
# $1 - name of conjur host factory (from policy)
# $2 - duration of eonjur host factory token in seconds
# $3 - name of variable pods will fetch from conjur
# $4 - name to give kubernetes deployment

declare CONJUR_HOST_FACTORY_TOKEN
main() {

        if [[ $# -ne 5 ]] ; then
                printf "\n\tUsage: %s <deployment-name> <host-factory-name> <hf-token-duration-secs> <variable-to-fetch> <sleep-time>\n\n" $0
                exit 1
        fi
        local deployment_name=$1; shift
        local host_factory_name=$1; shift
        local hf_duration=$1; shift
        local variable_name=$1; shift
        local sleep_time=$1; shift

	# authenticate (login) user
	user_authn  # get admin session token based on user name and password

				# convert hf name into url format (hex values for slashes, colons, etc.
	urlify $host_factory_name
	host_factory_name=$URLIFIED
        hf_tokens_get $host_factory_name # sets HF_TOKENS
        printf "\nHost factory %s:\n" $host_factory_name
        echo $HF_TOKENS | jq -r '.[]'
        TOKENS=$(echo $HF_TOKENS | jq -r ' .[] | .token')
        for tkn in $TOKENS; do
                printf "Revoking token: %s\n" $tkn
                hf_token_revoke $tkn
        done

				# show current state of host factory	
	hf_show $host_factory_name
	# create a host factory token
	hf_token_create $host_factory_name $hf_duration	   # sets CONJUR_HOST_FACTORY_TOKEN value
	printf "\nHF token is: %s\n" $CONJUR_HOST_FACTORY_TOKEN

	config_name="$deployment_name".config
	kubectl delete configmap $config_name >> /dev/null	# delete configmap if it exists
	# write out host factory name & token, variable name and deployment name in configmap
	kubectl create configmap $config_name \
		--from-literal=hf_name=$host_factory_name \
		--from-literal=hf_token=$CONJUR_HOST_FACTORY_TOKEN \
		--from-literal=var_name=$variable_name \
		--from-literal=sleep_time=$sleep_time

	kubectl get configmap $config_name -o yaml
}

###############################################
### Global utility declarations and definitions

# data specs and time math are not portable - set DATE_SPEC to the correct platform
readonly MAC_DATE='date -v+"$dur_time_secs"S +%Y-%m-%dT%H%%3A%M%%3A%S%z'
readonly LINUX_DATE='date --iso-8601=seconds --date="$dur_time_secs seconds"'
DATE_SPEC=$MAC_DATE
if [[ "$(uname -s)" == "Linux" ]]; then
        DATE_SPEC=$LINUX_DATE
fi

# get pointers to Conjur REST API endpoint and SSL certificate
source EDIT.ME
if [[ "$CONJUR_APPLIANCE_URL" = "" ]] ; then
	printf "\n\nEdit file EDIT.ME to set your appliance URL and certificate path.\n\n"
	exit 1
fi

#declare DEBUG_BREAKPT=""
declare DEBUG_BREAKPT="read -n 1 -s -p 'Press any key to continue'"

# global variables
declare ADMIN_SESSION_TOKEN
declare CONJUR_HOST_FACTORY_TOKEN
declare URLIFIED

##################
# USER AUTHN - get admin session token based on user name and password
# - no arguments
user_authn() {
        printf "\nEnter admin user name: "
        read admin_name
        printf "Enter the admin password (it will not be echoed): "
        read -s admin_pwd

        # Login user, authenticate and get API key for session
        local access_token=$(curl \
                                 -s \
                                --cacert $CONJUR_CERT_FILE \
                                --user $admin_name:$admin_pwd \
                                $CONJUR_APPLIANCE_URL/authn/users/login)

        local response=$(curl -s \
                        --cacert $CONJUR_CERT_FILE  \
                        --data $access_token \
                        $CONJUR_APPLIANCE_URL/authn/users/$admin_name/authenticate)
        ADMIN_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')

}

################
# URLIFY - converts '/' and ':' in input string to hex equivalents
# in: $1 - string to convert
# out: URLIFIED - converted string in global variable
urlify() {
	local str=$1; shift
	str=$(echo $str | sed 's= =%20=g') 
	str=$(echo $str | sed 's=/=%2F=g') 
	str=$(echo $str | sed 's=:=%3A=g') 
	str=$(echo $str | sed 's=+=-=g')   # added as hack to change + to - in timezone offset in linux date string
	URLIFIED=$str
}

################  MAIN   ################
# HOST FACTORY TOKEN CREATE a new HF token with a defined expiration date
# $1 - host factory id
# $2 - dur time - hf token lifespan in seconds
hf_token_create() {
        local hf_id=$1; shift
        local dur_time_secs=$1; shift

        local token_exp_time=$(eval $DATE_SPEC)
	urlify $token_exp_time
	token_exp_time=$URLIFIED
        printf "Token exp time= %s\n" $token_exp_time

        CONJUR_HOST_FACTORY_TOKEN=$( curl \
	 -s \
         --cacert $CONJUR_CERT_FILE \
         --request POST \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/host_factories/{$hf_id}/tokens?expiration=$token_exp_time \
         | jq -r '.[] | .token')
}

################
# HOST FACTORY SHOW - show info about host factory including all associated tokens
hf_show() {
        local hf_id=$1; shift

	printf "\nHost factory %s:\n" $hf_id
	curl \
	-s \
	--cacert $CONJUR_CERT_FILE \
	--header "Content-Type: application/json" \
	--header "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
	$CONJUR_APPLIANCE_URL/host_factories/{$hf_id} \
	| jq -r ' .tokens | .[] '
}

################
# HOST FACTORY TOKEN REVOKE (delete) the host factory token
hf_token_revoke() {
        local hf_token=$1; shift
        curl \
         -s \
         --cacert $CONJUR_CERT_FILE \
         --request DELETE \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/host_factories/tokens/$hf_token
}


################
# LIST ALL HF TOKENS - list all tokens for a host factory
# in: host factory id
# out: TOKENS array (global)
hf_tokens_get() {
        local hf_id=$1; shift

        HF_TOKENS=$( curl \
        -s \
        --cacert $CONJUR_CERT_FILE \
        --header "Content-Type: application/json" \
        --header "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/host_factories/{$hf_id} \
        | jq -r ' .tokens ' )
}

main "$@"
exit
