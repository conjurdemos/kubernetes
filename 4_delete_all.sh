kubectl delete -f conjur-service/
kubectl delete -f follower-service
kubectl delete pods --all
rm standby-seed.tar follower-seed.tar
