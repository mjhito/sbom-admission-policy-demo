#!/usr/bin/env bash
set -eou pipefail
IFS=$'\t'

# shellcheck source=./../setenv.sh
. ./setenv.sh

# Function to print the usage information and exit the script with a non-zero status
function print_usage {
    echo "Usage: bash destroy.sh"
    echo "$*"
    exit 1
}

kind delete cluster --name=$CLUSTER_NAME