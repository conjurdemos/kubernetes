#!/bin/bash -e

declare CONJUR_NAMESPACE=conjur

main() {
  startup_env
  create_namespace
}

##############################
##############################

##############################
# STEP 1 - startup environment
startup_env() {
  if [[ "$(minikube status | awk '/minikube:/ {print $2}')" == "Stopped" ]]; then
     minikube start
  fi  
  # use the minikube docker environment
  eval $(minikube docker-env)
}

create_namespace() {
  if kubectl get namespace | grep -w $CONJUR_NAMESPACE > /dev/null; then
    echo "Namespace '$CONJUR_NAMESPACE' exists. I wont create it."
  else
    kubectl create namespace $CONJUR_NAMESPACE
  fi

  kubectl config set-context conjur --namespace=conjur --cluster=minikube --user=minikube
}

main $@
