# scalability-k8s

Goal: The scalability-demo implemented in Kubernetes, with a full Conjur cluster of 1 Master, 2 Standbys (& Followers eventually).

Scenario: Spin up a bunch of minimal containers, each of which fetches a secret every few seconds in a continuous loop. Change the secret, deny access, failover to standby and watch effects.

Prerequisites:
- minikube
- kubectl

Cluster management:
- 1_load_container.sh - initial load of Conjur appliance container (see comments for faster procedure)
- 2_startup-conjur-service.sh - sets up master and 2 standbys using yaml files conjur-service directory
- 3_cluster_failover.sh - fails over to standby pod tagged as synchronous
- 4_delete_all.sh - deletes entire cluster
- time_sync.sh - used as needed to sync vbox clock with host
- conjur-service (directory) - holds all k8s yaml files to launch conjur-service
  - conjur-service.yaml - top level, static IP address for service
  - conjur-jade.yaml - one of three statefulSets for master, standby, standby
  - conjur-quartz.yaml - one of three statefulSets for master, standby, standby
  - conjur-onyx.yaml - one of three statefulSets for master, standby, standby
  - conjur.json - configuration file to reduce resource demands of each container

scale_demo (directory) - scripts and support for running the scalability demo
- 0_demo_init.sh - creates users, updates passwords, loads weave scope, etc.
- 1_load_app_policy.sh - loads webapp1-policy.yml
- 2_setup_deployment.sh - generates HF token and stashes meta info in a configMap
- 3_deploy.sh - launches deployment for webapp1
- 4_delete_deployment.sh - deletes entire deployment
- 5_cleanup_host_factory.sh - revokes (deletes) old HF tokens
- audit_policy.sh - compares a policy against current Conjur state, reports any diffs
- watch_container_log.sh - alternative to weave scope, shows container activity
- users-policy.yml - defines demo users
- webapp1-policy.yml - defines webapp1 security schema
- webapp1.yaml - k8s deployment description
- EDIT.ME - sourced by scripts, replacement for .conjurrc
- load_policy.sh - loads a supplied policy file into conjur
- setup_deployment.sh - sets up a deployment per input parameters
- cleanup_host_factory.sh - revokes all tokens for a given host factory
- launch_deployment.sh - launches a deployment setup by setup_deployment.sh
- build (directory):
  - Dockerfile - build description for demo container
  - build.sh - script that generates build
  - webapp1.sh - "application" that runs in each demo container in deployment

- cli_client (directory) - experimental, for seeing how much cluster management can be done from inside the cluster.
  - cli-conjur.yaml
  - cli-shell.sh
  - cli-startup.sh
  - cli_image_build
  
- follower-service-NOT_FINISHED (directory)
  - follower-service.yaml - deployment description for followers. currently stops before calling "evoke configure follower" due to issues.
