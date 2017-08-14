#!/bin/bash 
# Assumptions:
# - docker, minikube and kubectl are already installed

declare ROOT_KEY=Cyberark1
declare CONJUR_CLUSTER_ACCT=dev
declare CONJUR_MASTER_DNS_NAME=conjur-master
declare MASTER_POD_NAME=conjur-master-headless-0

# sudo not required for mac, but is for linux
DOCKER="docker"
if [[ "$(uname -s)" == "Linux" ]]; then
        DOCKER="sudo docker"
fi

##############################
##############################
# MAIN - takes no command line arguments

main() {
	startup_env
	startup_conjur_service
#	configure_conjur_cluster
}

##############################
##############################

##############################
# STEP 1 - startup environment
startup_env() {
	# use the minikube docker environment
	eval $(minikube docker-env)
}

##############################
# STEP 2 - start service and label pods w/ roles
startup_conjur_service() {
				# delete configmap if it exists
        kubectl delete configmap conjur-master-config >> /dev/null

        			# write out cluster config parameters
        kubectl create configmap conjur-master-config \
                --from-literal=master-pod-name=$MASTER_POD_NAME \
                --from-literal=conjur-master-dns-name=$CONJUR_MASTER_DNS_NAME \
                --from-literal=root-key=$ROOT_KEY \
                --from-literal=conjur-cluster-acct=$CONJUR_CLUSTER_ACCT

				# start up conjur services from yaml
	kubectl create -f ./etc/conjur-master-headless.yaml
				# start up load balancer
	kubectl create -f ./etc/haproxy-headless.yaml

				# give containers time to get running
}

##############################
# STEP 3 - configure cluster based on role labels
# Input: none
configure_conjur_cluster() {
				# get name of stateful set that is labeled conjur-master
				# configure Conjur master server using evoke
	kubectl exec -it $MASTER_POD_NAME -- evoke configure master -h $CONJUR_MASTER_DNS_NAME -p $ROOT_KEY -j ./etc/conjur.json $CONJUR_CLUSTER_ACCT

        			# prepare seed files for standbys and followers
        kubectl exec -it $MASTER_POD_NAME -- bash -c "evoke seed standby > /tmp/standby-seed.tar"
	kubectl cp $MASTER_POD_NAME:/tmp/standby-seed.tar ./etc/standby-seed.tar
        kubectl exec -it $MASTER_POD_NAME -- bash -c "evoke seed follower $CONJUR_MASTER_DNS_NAME > /tmp/follower-seed.tar"
	kubectl cp $MASTER_POD_NAME:/tmp/follower-seed.tar ./etc/follower-seed.tar


        			# get name of statefulSet that is labeled sync standby
	kubectl cp ./standby-seed.tar $SYNC_STANDBY_POD_NAME:/tmp/standby-seed.tar
	kubectl exec -it $SYNC_STANDBY_POD_NAME -- bash -c "evoke unpack seed /tmp/standby-seed.tar"
	kubectl exec -it $SYNC_STANDBY_POD_NAME -- evoke configure standby -i $MASTER_POD_IP
				# force sync replication to designated sync standby
        kubectl exec -it $MASTER_POD_NAME -- bash -c "evoke replication sync --force"


        			# get name of statefulSet that is labeled async standby
        local ASYNC_STANDBY_SET=$(kubectl get statefulSet \
                -l app=async-conjur-standby --no-headers \
                | awk '{ print $1 }' )
	local ASYNC_STANDBY_POD_NAME=$ASYNC_STANDBY_SET-0
        			# copy seed file to async standby, unpack and configure
	kubectl cp ./standby-seed.tar $ASYNC_STANDBY_POD_NAME:/tmp/standby-seed.tar
	kubectl exec -it $ASYNC_STANDBY_POD_NAME -- bash -c "evoke unpack seed /tmp/standby-seed.tar"
	kubectl exec -it $ASYNC_STANDBY_POD_NAME -- evoke configure standby -i $MASTER_POD_IP
}

main $@
