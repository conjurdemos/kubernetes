#!/bin/bash -x
# Fails over to statefulSet tagged sync-conjur-standby
#  - the current master is assumed unreachable and destroyed
#  - the async standby is rebased to the sync standby
#  - the sync standby is promoted to master 
#  - a new sync standby is created with the old masters StatefulSet
#
# Note: k8s naming convention gives pods the name of the set w/ appended
# with a hyphen and ordinal number starting with 0.

main() {
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

	# destroy old master 
	# k8s will start new unconfigured pod
	kubectl delete pods $OLD_MASTER_POD
	# former master becomes new sync standby
	NEW_SYNC_STANDBY_SET=$OLD_MASTER_SET
	NEW_SYNC_STANDBY_POD=$OLD_MASTER_POD

	# KEG: there is no guarantee that this is the right server to promote
	# The proper way to know which server to promote is to compare their replication_log_pos

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

	# new sync standby = old master
	# make sure it's ready for configuration
	while [[ $(kubectl get pods | awk "/$NEW_SYNC_STANDBY_POD/ {print \$3}") != "Running" ]]; do
		sleep 5
	done

	# copy seed file, unpack and configure
	kubectl cp tmp/standby-seed.tar $NEW_SYNC_STANDBY_POD:/tmp/standby-seed.tar
	kubectl exec -it $NEW_SYNC_STANDBY_POD -- bash -c "evoke unpack seed /tmp/standby-seed.tar"
	kubectl exec -it $NEW_SYNC_STANDBY_POD -- evoke configure standby -j /etc/conjur.json -i $NEW_MASTER_POD_IP

	# update labels
	kubectl label --overwrite statefulSet $NEW_SYNC_STANDBY_SET app=sync-conjur-standby
	kubectl label --overwrite pods $NEW_SYNC_STANDBY_POD app=sync-conjur-standby

}

main $@
