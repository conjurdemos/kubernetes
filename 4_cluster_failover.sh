#!/bin/bash -x

set -o pipefail

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
	printf "deleting current master...\n"
	OLD_MASTER_POD=$(kubectl get pod -l role=master --no-headers | awk '{ print $1 }' )
	# replace old master w/ unconfigured pod
	kubectl get pod $OLD_MASTER_POD -n default -o yaml | kubectl replace --force -f -
	kubectl label --overwrite pod $OLD_MASTER_POD role=unset
}

#############################
# STOP_ALL_REPLICATION
# stop replication in all standbys

stop_all_replication() {
	printf "stopping replication...\n"
	pod_list=$(kubectl get pods -lrole=standby --no-headers| awk '{print $1}')
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
	printf "identifying standby to promote to master...\n"
	# get list of pods that arent master
	pod_list=$(kubectl get pods -lrole=standby --no-headers | awk '{print $1}')
	# find standby w/ most replication bytes
	most_repl_bytes=0

	for pod_name in $pod_list; do
		pod_ip=$(kubectl describe pod $pod_name | awk '/IP:/ {print $2}')
		health_stats=$(kubectl exec $pod_name curl localhost/health)
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
	printf "pod %s will be the new master...\n" $use_this_one
}

##########################
# VERIFY_MASTER_CANDIDATE
#
# does dry run of rebase for all other standbys to candidate
#

verify_master_candidate() {
	printf "verifying candidate as viable master...\n"
	# get candidate pod IP address
	candidate_pod=$(kubectl get pods -lrole=candidate --no-headers | awk '{print $1}')
	candidate_ip=$(kubectl describe pod $candidate_pod | awk '/IP:/ { print $2 }')
	# get list of pods that aren't master
	pod_list=$(kubectl get pods -lrole=standby --no-headers | awk '{print $1}')

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
	printf "rebasing other standbys to new master...\n"
	# get candidate pod IP address
	candidate_pod=$(kubectl get pods -lrole=candidate --no-headers | awk '{print $1}')
	candidate_ip=$(kubectl describe pod $candidate_pod | awk '/IP:/ { print $2 }')
	# get list of standby pods
	pod_list=$(kubectl get pods -lrole=standby --no-headers | awk '{print $1}')

	# rebase remaining standbys to new master
	for pod_name in $pod_list; do
		kubectl exec -t $pod_name -- evoke replication rebase $candidate_ip
	done
}

########################
# PROMOTE_CANDIDATE
#
# promotes selected pod to the role of master

promote_candidate() {
	printf "promoting candidate to master...\n"
	# get candidate pod IP address
	candidate_pod=$(kubectl get pods -lrole=candidate --no-headers | awk '{print $1}')
	# promote new master
	kubectl exec -t $candidate_pod -- evoke role promote
	# update label
	kubectl label --overwrite pod $candidate_pod role=master
}

########################
# CONFIGURE_OLD_MASTER
#
# configure OLD_MASTER_POD to be a standby

configure_new_standby() {
	printf "configuring former master pod as standby...\n"
	# get master pod IP address
	master_pod=$(kubectl get pods -lrole=master --no-headers | awk "{print \$1}")
	master_ip=$(kubectl describe pod $master_pod | awk '/IP:/ { print $2 }')
					# wait until replaced master pod is running
	new_pod=$(kubectl get pod -lrole=unset --no-headers | awk "{print \$1}")
	while [[ $(kubectl get pod $new_pod --no-headers | awk "{print \$3}") != 'Running' ]]; do	
		sleep 5
	done
					# wait until replaced master pod database quiesces
	health_stats=$(kubectl exec $new_pod curl localhost/health)
	while [[ "$(echo $health_stats | jq -r ".database.ok"l" != "true" ]]; then
		sleep 5
	done)

	# copy seed file, unpack and configure
 	kubectl cp ./$CONFIG_DIR/standby-seed.tar $new_pod:/tmp/standby-seed.tar
  kubectl exec -it $new_pod -- bash -c "evoke unpack seed /tmp/standby-seed.tar"
  kubectl exec -it $new_pod -- evoke configure standby -j /etc/conjur.json -i $master_ip
	kubectl label --overwrite pod $new_pod role=standby

	# turn on sync replication
  kubectl exec -it $master_pod -- bash -c "evoke replication sync"
}

main $@
