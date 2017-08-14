#!/bin/bash -x

if [[ ! -f /root/check.log ]]; then
   touch /root/check.log
fi

echo "Input parameters: " $1 $2 $3 $4 >> /root/check.log
server_address=$3
echo "server_address: " $server_address  >> /root/check.log

result=$(curl -k -s https://$server_address/health)
conjur_ok=$(echo $result | jq '.ok')
if [[ "$conjur_ok" == "true" ]]; then
	echo "Conjur is OK" >> /root/check.log
	exit 0
fi
echo "Conjur is NOT OK" >> /root/check.log
echo "curl returned:" $result  >> /root/check.log
echo "check status value:" $conjur_ok >> /root/check.log
exit -1
