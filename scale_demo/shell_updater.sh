while [[ 1 == 1 ]]; do
	conjur variable values add webapp1/database_password $(openssl rand -hex 12)
	sleep 5
done
