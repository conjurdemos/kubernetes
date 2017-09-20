# Kubernetes

Demonstrates the use of Conjur in Kubernetes for machine identity and secrets delivery.

As a secondary objective, which may be refactored to a separate demo in the future, this repo shows a multi-node master cluster with failover. 

Prerequisites:
- [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/).
- [Conjur CLI](https://github.com/cyberark/conjur-cli/releases) installed locally.
- [conjur-authn-k8s_0.2.0.0-91ac501_amd64.deb.zip](https://github.com/conjurdemos/scalability-k8s/files/1220010/conjur-authn-k8s_0.2.0.0-91ac501_amd64.deb.zip). Download to the directory "conjur_server_build" and unzip it.

# Cluster management

- 0_init.sh - Setup the docker environment and create the `conjur` Kubernetes namespace.
- 1_build_all.sh - Build images used by the demo.
- 2a_startup_solo_master.sh - Run a single `conjur-master` Pod.
- 2b_startup_master_cluster.sh - Run a master and 2 standbys, plus a `conjur-master` service which uses HAProxy.
- 3_startup-followers.sh - Create the `conjur-follower` Service.
- 4_cluster_failover.sh - Fail over to a standby pod and re-build the master as a standby. This will not work in solo master mode.
- 5_delete_all.sh - Deletes the entire cluster.
- time_sync.sh - use as needed to sync vbox clock with host.

# `authn-k8s` scale demo

`./authn_k8s_scale_demo` (directory) - scripts and support for running the scalability demo using authn-k8s

- 0_demo_init.sh - configure and login the local command-line interface.
- 1_load_k8s_policy.sh - loads the policies which are performed by the Kubernetes admi.n
- 2_load_app_policy.sh - loads the application policy, which would be managed by an application team.
- 3_load_db_policy.sh - loads the database policy, which would be managed by a DBA team.
- 4_deploy.sh - deploys the `webapp` application and starts the containers fetching secrets.
- 5_delete_deployment.sh - deletes all the k8s objects.
- webapp.yaml - Kubernetes description for the `webapp` application. 

# API key scale demo (deprecated)

`./scale_demo` (directory) - scripts and support for running the scalability demo

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
- EDIT.ME - sourced by scripts in lieu of .conjurrc for RESTful apps
- load_policy.sh - loads a policy file into conjur
- setup_deployment.sh - sets up a deployment per input parameters
- launch_deployment.sh - launches a deployment setup by setup_deployment.sh
- cleanup_host_factory.sh - revokes all tokens for a given host factory
- build (directory) - for building the deployment container image
  - Dockerfile - build description for demo container
  - build.sh - script that generates build
  - webapp1.sh - "application" that runs in each demo container in deployment

