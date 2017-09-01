kubectl create -f cli-conjur.yaml
sleep 3
kubectl exec -it conjur-cli -- bash
