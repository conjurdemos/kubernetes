#!/bin/bash -e

set -o pipefail

pushd ./haproxy
./build.sh
popd
