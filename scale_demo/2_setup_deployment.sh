#!/bin/bash
printf "\nDeployment: webapp1\n"
printf "HF: webapp1/tomcat_factory\n"
printf "HF lifetime (secs):  500\n"
printf "Variable: webapp1/database_password\n"
printf "Sleep time: 5\n"
./setup_deployment.sh webapp1 webapp1/tomcat_factory 500 webapp1/database_password 5

