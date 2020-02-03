#!/bin/bash
set -eo pipefail

cd buildkite

export TF_ACC=1
export BUILDKITE_ORGANIZATION=$(git remote show origin -n | grep h.URL | sed 's/.*://;s/\/.*//;s/.git$//')

go test -v