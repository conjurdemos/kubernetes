#!/bin/bash 

printf "\n\n\nExecuting within the container...\n\n"

# environment variables from configmap
# ENDPOINT - environment variable
# DEPLOYMENT_NAME - environment variable
# VAR_ID - environment variable name to fetch
# SLEEP_TIME - environment variable name to fetch

declare CONT_NAME=$(hostname)
declare LOGFILE=cc.log
declare INPUT_FILE=/shared/api_key

# for logfile to see whats going on
touch $LOGFILE

# get API_KEY cached in file in shared volume
# ket is put there by the init container for the pod
# which pulls it from the configMap named webapp1
read API_KEY < $INPUT_FILE

echo "Endpoint is:" $ENDPOINT >> $LOGFILE

while [ 1=1 ]; do
        # Login w/ host API key to authenticate and get session token
        host_login=host%2F$DEPLOYMENT_NAME
        response=$(curl -s \
         -k \
         --request POST \
         --data-binary $API_KEY \
         $ENDPOINT/authn/users/{$host_login}/authenticate)
        ACCESS_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')

	# FETCH variable value
	DB_PASSWORD=$(curl -s -k \
         --request GET \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$ACCESS_TOKEN\"" \
         $ENDPOINT/variables/{$VAR_ID}/value)

  	echo $(date) "The DB Password is: " $DB_PASSWORD >> $LOGFILE
	sleep $SLEEP_TIME 
done

exit
