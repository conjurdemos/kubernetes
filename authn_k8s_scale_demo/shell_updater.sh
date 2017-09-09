while [[ 1 == 1 ]]; do
	new_pwd=$(openssl rand -hex 12)
	conjur variable values add db/password $new_pwd
	echo "New password is:" $new_pwd
	sleep 5
done
