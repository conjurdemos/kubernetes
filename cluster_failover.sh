#!/bin/bash -x
# Takes one command line arguments:
#	new-master - will be either the current sync or async standby
#
# If sync standby is specified:
#  - the current master is assumed unreachable and destroyed
#  - the async standby is rebased to the sync standby
#  - the sync standby is promoted to master 
#  - a new sync standby is created with the old masters StatefulSet
#
# If async standby is specified:
#  - both current master and sync standy are assumed unreachable and destroyed
#  - a new sync standby is created with the old master's statefulSet
#  - the async standby is promoted to master
#  - a new async standby is created with the old sync standby's statefulSet

main() {
	if [[ $# -ne 1 ]] ; then
		printf "\n\tUsage: %s [sync-conjur-standby | async-conjur-standby]\n\n"
		exit 1
	fi
	local failover_to=$1; shift

	local OLD_MASTER_SET, OLD_MASTER_POD
	local NEW_MASTER_SET, NEW_MASTER_POD
	local NEW_SYNC_STANDBY_SET, NEW_SYNC_STANDBY_POD
	local NEW_ASYNC_STANDBY_SET, NEW_ASYNC_STANDBY_POD
	local ASYNC_STANDBY_SET, ASYNC_STANDBY_POD
				# get set name of failed master
	OLD_MASTER_SET=$(kubectl get statefulSet \
		-l app=conjur-master --no-headers \
		| awk '{ print $1 }' )
	OLD_MASTER_POD=$OLD_MASTER_SET-0

	if [[ $failover_to = sync-conjur-standby ]] ; then
					# destroy old master 
					# k8s will start new unconfigured pod
		kubectl delete pods $OLD_MASTER_POD
				# former master becomes new sync standby
		NEW_SYNC_STANDBY_SET=$OLD_MASTER_SET
		NEW_SYNC_STANDBY_POD=$OLD_MASTER_POD
				# current sync standby is new master
		NEW_MASTER=$(kubectl get statefulSet \
			-l app=sync-conjur-standby --no-headers \
			| awk '{ print $1 }' )
		NEW_MASTER_POD=$NEW_MASTER-0
		NEW_MASTER_POD_IP=$(kubectl describe pod \
					$NEW_MASTER_POD \
					| awk '/IP:/ { print $2 }')

					# adjust async standby to new master
		ASYNC_STANDBY_SET=$(kubectl get statefulSet \
			-l app=async-conjur-standby --no-headers \
			| awk '{ print $1 }' )
		ASYNC_STANDBY_POD=$ASYNC_STANDBY_SET-0

					# stop replication on surviving standby
		kubectl exec -t $ASYNC_STANDBY_POD -- evoke replication stop
					# verify other standby deems new master worthy
		verify_message=$(kubectl exec -t $ASYNC_STANDBY_POD -- \
			evoke replication rebase --dry-run $NEW_MASTER_POD_IP)
		echo $verify_message
					# rebase remaining standby to new master
		kubectl exec -t $ASYNC_STANDBY_POD -- \
			evoke replication rebase $NEW_MASTER_POD_IP
					# promote new master
		kubectl exec -t $NEW_MASTER_POD -- evoke role promote

					# update labels
		kubectl label --overwrite statefulSet $NEW_MASTER app=conjur-master
		kubectl label --overwrite pods $NEW_MASTER_POD app=conjur-master
		kubectl label --overwrite statefulSet $NEW_SYNC_STANDBY_SET app=sync-conjur-standby
		kubectl label --overwrite pods $NEW_SYNC_STANDBY_POD app=sync-conjur-standby

					# copy seed file, unpack and configure
        	kubectl cp ./standby-seed.tar $NEW_SYNC_STANDBY_POD:/tmp/standby-seed.tar
	        kubectl exec -it $NEW_SYNC_STANDBY_POD -- bash -c "evoke unpack seed /tmp/standby-seed.tar"
	        kubectl exec -it $NEW_SYNC_STANDBY_POD -- evoke configure standby -i $NEW_MASTER_POD_IP

					# force sync replication to designated sync standby
	        kubectl exec -it $NEW_MASTER_POD -- evoke replication sync --force

	elif [[ $failover_to = async-conjur-standby ]] ; then
		NEW_MASTER=$(kubectl get statefulSet \
			-l app=async-conjur-standby --no-headers \
			| awk '{ print $1 }' )
		NEW_ASYNC_STANDBY=$(kubectl get statefulSet \
			-l app=sync-conjur-standby --no-headers \
			| awk '{ print $1 }' )
		kubectl label --overwrite statefulSet $NEW_MASTER app=conjur-master
		kubectl label --overwrite pods $NEW_MASTER-0 app=conjur-master
		kubectl label --overwrite statefulSet $NEW_SYNC_STANDBY app=sync-conjur-standby
		kubectl label --overwrite pods $NEW_SYNC_STANDBY-0 app=sync-conjur-standby
		kubectl label --overwrite statefulSet $NEW_ASYNC_STANDBY app=async-conjur-standby
		kubectl label --overwrite pods $NEW_ASYNC_STANDBY-0 app=async-conjur-standby
	else
		printf "Must failover to either sync-conjur-standby or async-conjur-standby\n\n"
	fi
}

main $@
