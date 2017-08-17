#!/bin/bash 
# Fails over to the most up-to-date, healthy standby
#  - the current master is assumed unreachable and destroyed
#  - all replication activity is halted
#  - the most up-to-date healthy standby is identified as the new master
#  - all other standbys are rebased to the new master
#  - that new master is promoted 
#  - a new sync standby is created with the old masters pod
#  - sychronous replication is re-established

declare CONFIG_DIR=conjur-service

main() {
	printf "\nThis script has to be run in a shell within the cluster\n"
	printf "in order to connect to the standby containers. They are\n"
	printf "not exposed to the external IP address like the master.\n\n"
	read -n 1 -s -p 'Press any key to continue, Ctrl-C to abort'

	delete_current_master
	stop_all_replication
	identify_standby_to_promote
	verify_master_candidate	
	rebase_other_standbys
	promote_candidate
	configure_new_standby
}

##########################
# DELETE_CURRENT_MASTER
#
# current master pod is role label is "master"

delete_current_master() {
	OLD_MASTER_POD=$(kubectl get pod -l role=master --no-headers | awk '{ print $1 }' )
	# destroy old master 
	# k8s will start new unconfigured pod
	kubectl delete pod $OLD_MASTER_POD
}

#############################
# STOP_ALL_REPLICATION
# stop replication in all standbys

stop_all_replication() {
	pod_list=$( kubectl get pods -lrole=standby | awk '/conjur-master/ {print $1}')
	for pod_name in $pod_list; do
 		kubectl exec -t $pod_name -- evoke replication stop
	done
}


#############################
# IDENTIFY_STANDBY_TO_PROMOTE
#
# identify standby where both:
#	- DB is OK and 
#	- replication status xlog bytes is greatest
#

identify_standby_to_promote() {
	# get list of pods that arent master
	pod_list=$(kubectl get pods -lrole=standby | awk '/conjur-master/ {print $1}')
	# find standby w/ most replication bytes
	most_repl_bytes=0

	for pod_name in $pod_list; do
		pod_ip=$(kubectl describe pod $pod_name | awk '/IP:/ {print $2}')
		health_stats=$(curl -s -k https://$pod_ip/health)
		db_ok=$(echo $health_stats | jq -r ".database.ok")
		if [[ "$db_ok" != "true" ]]; then
			continue
		fi
		pod_repl_bytes=$(echo $health_stats | jq -r ".database.replication_status.pg_last_xlog_replay_location_bytes")
		if [[ $pod_repl_bytes > $most_repl_bytes ]]; then
			most_repl_bytes=$pod_repl_bytes
			use_this_one=$pod_name
		fi
	done
	# label winning pod as candidate
	kubectl label --overwrite pod $use_this_one role=candidate
}

##########################
# VERIFY_MASTER_CANDIDATE
#
# does dry run of rebase for all other standbys to candidate
#

verify_master_candidate() {
	# get candidate pod IP address
	candidate_pod=$(kubectl get pods -lrole=candidate | awk '/conjur-master/ {print $1}')
	candidate_ip=$(kubectl describe pod $candidate_pod | awk '/IP:/ { print $2 }')
	# get list of pods that aren't master
	pod_list=$(kubectl get pods -lrole=standby | awk '/conjur-master/ {print $1}')

	for pod_name in $pod_list; do
		# verify new master is worthy
		verify_message=$(kubectl exec -t $pod_name -- evoke replication rebase --dry-run $candidate_ip)
		echo $verify_message
	done
}

##########################
# REBASE_OTHER_STANDBYS
#
# rebases all other standbys to candidate

rebase_other_standbys() {
	# get candidate pod IP address
	candidate_pod=$(kubectl get pods -lrole=candidate | awk '/conjur-master/ {print $1}')
	candidate_ip=$(kubectl describe pod $candidate_pod | awk '/IP:/ { print $2 }')
	# get list of standby pods
	pod_list=$(kubectl get pods -lrole=standby | awk '/conjur-master/ {print $1}')

	# rebase remaining standbys to new master
	for pod_name in $pod_list; do
		kubectl exec -t $pod_name -- evoke replication rebase $candidate_ip
	done
}

promote_candidate() {
	# get candidate pod IP address
	candidate_pod=$(kubectl get pods -lrole=candidate | awk '/conjur-master/ {print $1}')
	# promote new master
	kubectl exec -t $candidate_pod -- evoke role promote
	# update label
	kubectl label --overwrite pods $candidate_pod role=master
}

########################
# CONFIGURE_OLD_MASTER
#
# configure OLD_MASTER_POD to be a standby

configure_new_standby() {
	# get master pod IP address
	master_pod=$(kubectl get pods -lrole=master | awk '/conjur-master/ {print $1}')
	master_ip=$(kubectl describe pod $master_pod | awk '/IP:/ { print $2 }')
	# get candidate pod IP address
	new_pod=$(kubectl get pods -lrole=unset | awk '/conjur-master/ {print $1}')
	# new standby = old master
	# wait till it's running
  while [[ $(kubectl get pods | awk "/$new_pod/ {print \$3}") != "Running" ]]; do
  	sleep 5
  done
	# copy seed file, unpack and configure
	# copy conjur pgsql memory limits to pods
	kubectl cp ./$CONFIG_DIR/conjur.json $new_pod:/etc/conjur.json

 	kubectl cp ./$CONFIG_DIR/standby-seed.tar $new_pod:/tmp/standby-seed.tar
  kubectl exec -it $new_pod -- bash -c "evoke unpack seed /tmp/standby-seed.tar"
  kubectl exec -it $new_pod -- evoke configure standby -j /etc/conjur.json -i $master_ip
	kubectl label --overwrite pods $new_pod role=standby

	# turn on sync replication
  kubectl exec -it $master_pod -- bash -c "evoke replication sync"
}

main $@
