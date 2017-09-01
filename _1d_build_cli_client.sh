#!/bin/bash -e

set -o pipefail

pushd ./cli_client/cli_image_build
./build.sh
popd
