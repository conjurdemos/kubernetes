#!/bin/bash -e

set -o pipefail

# Assumptions:
# - minikube and kubectl are already installed

# directory of yaml
declare CONFIG_DIR=./conjur-service

declare MASTER_POD_NAME=conjur-master
declare ADMIN_PASSWORD=Cyberark1
declare CONJUR_CLUSTER_ACCT=dev
declare CONJUR_NAMESPACE=conjur
declare CONJUR_MASTER_DNS_NAME=conjur-master.$CONJUR_NAMESPACE.svc.cluster.local
declare CONJUR_FOLLOWER_DNS_NAME=conjur-follower.$CONJUR_NAMESPACE.svc.cluster.local

##############################
##############################
# MAIN - takes no command line arguments

main() {
  startup_master
  configure_master
  startup_client
  print_config
}

##############################
##############################


##############################
startup_master() {
  kubectl config use-context conjur

  # start up conjur services from yaml
  kubectl create -f $CONFIG_DIR/conjur-master-solo.yaml

  # give containers time to get running
  echo "Waiting for conjur-master to launch"
  sleep 5
  while [[ $(kubectl exec conjur-master evoke role) != "blank" ]]; do
    echo -n '.'
    sleep 5
  done
  echo "done"
}

##############################
# STEP 3 - configure cluster based on role labels
# 

configure_master() {
  kubectl config use-context conjur

  printf "Configuring solo %s...\n" $MASTER_POD_NAME
  # configure Conjur master server using evoke
  kubectl exec $MASTER_POD_NAME -- evoke configure master \
    -j /etc/conjur.json \
    -h $CONJUR_MASTER_DNS_NAME \
    --master-altnames conjur-master \
    --follower-altnames conjur-follower \
    -p $ADMIN_PASSWORD \
    $CONJUR_CLUSTER_ACCT

  printf "Preparing seed files...\n"
  # prepare seed files for standbys and followers
  kubectl exec $MASTER_POD_NAME evoke seed standby > $CONFIG_DIR/standby-seed.tar
  kubectl exec $MASTER_POD_NAME evoke seed follower $CONJUR_FOLLOWER_DNS_NAME > $CONFIG_DIR/follower-seed.tar
}

startup_client() {
  echo "Starting up the client Pod"

  pushd cli_client
  ./deploy.sh
  popd

  kubectl config use-context conjur
}

print_config() {
  # get internal/external IP addresses
  CLUSTER_IP=$(kubectl describe svc conjur-master | awk '/IP:/ { print $2; exit}')
  EXTERNAL_IP=$(kubectl describe svc conjur-master | awk '/External IPs:/ { print $3; exit}')

  # inform user of IP addresses 
  printf "\nInside Kubernetes, you can reach the Conjur master at: conjur-master.%s.svc.cluster.local\n" $CONJUR_NAMESPACE 
  printf "\nOutside the cluster, add this line to /etc/hosts:\n\n\t%s\tconjur-master\n\n" $EXTERNAL_IP  
}

main $@
