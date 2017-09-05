#!/bin/bash -ex

master_pod=$(kubectl get pod -l role=master --no-headers | awk '{ print $1 }')

function evokecmd() {
  interactive=$1
  if [ $interactive = '-i' ]; then
    shift
    kubectl exec -i $master_pod -- $@
  else
    kubectl exec $master_pod -- $@
  fi
}
