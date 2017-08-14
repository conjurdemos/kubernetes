#!/bin/bash -ex

MASTER_SET=$(kubectl get statefulSet \
      -l app=conjur-master --no-headers \
      | awk '{ print $1 }' )
MASTER_POD_NAME=$MASTER_SET-0

function evokecmd() {
  interactive=$1
  if [ $interactive = '-i' ]; then
    shift
    kubectl exec -i $MASTER_POD_NAME -- $@
  else
    kubectl exec $MASTER_POD_NAME -- $@
  fi
}
