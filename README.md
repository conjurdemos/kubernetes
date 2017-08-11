# scalability-k8s

Goal: The scalability-demo implemented in Kubernetes, with a full Conjur cluster of 1 Master, 2 Standbys (& Followers eventually).

Scenario: Spin up a bunch of minimal containers, each of which fetches a secret every few seconds in a continuous loop. Change the secret, deny access, failover to standby and watch effects.

Prerequisites:
- minikube
- kubectl

Cluster management:
- 1_startup-conjur-service.sh - sets up master and 2 standbys using yaml files conjur-service directory
- 2_cluster_failover.sh - fails over to standby pod tagged as synchronous
- 3_delete_all.sh - deletes entire cluster
- time_sync.sh - used as needed to sync vbox clock with host
- conjur-service (directory)
  - conjur-service.yaml
  - conjur-jade.yaml
  - conjur-quartz.yaml
  - conjur-onyx.yaml	

scale_demo (directory) - scripts and support for running the scalability demo
- 0_demo_init.sh
- 1_load_app_policy.sh
- 2_setup_deployment.sh
- 3_deploy.sh
- 4_delete_deployment.sh
- 5_cleanup_host_factory.sh
- audit_policy.sh
- load_policy.sh
- watch_container_log.sh
- users-policy.yml
- webapp1-policy.yml
- webapp1.yaml
- EDIT.ME
- setup_deployment.sh
- cleanup_host_factory.sh
- launch_deployment.sh
- build (directory):
  - Dockerfile
  - build.sh
  - webapp1.sh

- cli_client (directory) - experimental, for seeing how much cluster management can be done from inside the cluster.
  - cli-conjur.yaml
  - cli-shell.sh
  - cli-startup.sh
  - cli_image_build
  
- follower-service-NOT_FINISHED (directory)
  - follower-service.yaml
