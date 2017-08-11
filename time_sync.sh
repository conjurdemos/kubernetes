# syncs clock in minikube vm w/ host clock
# run this when you can't login to the conjur UI
minikube ssh -- docker run -i --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y)
