#!/usr/bin/env bash

# Exit the script on any error, unset variable, or command failure in a pipeline.
set -xeou pipefail
IFS=$'\t\n'

# Function to print the usage information and exit the script with a non-zero status
function print_usage {
    echo "Usage: bash deploy.sh [--kind] [--demo]"
    exit 1
}

# Function to handle errors globally and print a custom error message
function handle_error {
    echo "Error on line $1"
    exit 1
}

# Trap any error and call the handle_error function
trap 'handle_error $LINENO' ERR

# Ensure required scripts are available before proceeding
function check_required_files {
    for file in "./setenv.sh" "./scripts/prepare.sh"; do
        if [[ ! -f "$file" ]]; then
            echo "Error: Required file $file is missing"
            exit 1
        fi
    done
}

# Check required files
check_required_files

# Source the environment and preparation scripts
. ./setenv.sh
. ./scripts/prepare.sh

# Check if the correct number of arguments are provided
if [ $# -eq 0 ]; then
    print_usage
fi

# Check environment variables exist
function check_env_vars {
    local required_vars=("CLUSTER_NAME" "REGISTRY_URL"\
        "REGISTRY_USERNAME" "REGISTRY_PASSWORD" \
        "REGISTRY_EMAIL" "SBOM_FORMAT")

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "Error: Required environment variable $var is not set."
            exit 1
        fi
    done
}

# Call the function to check env vars
check_env_vars

# Flags
deploy_kind=false
deploy_demo=false

# Parse the flags
for arg in "$@"; do
    case $arg in
        --kind)
            deploy_kind=true
            ;;
        --demo)
            deploy_demo=true
            ;;
        *)
            echo "Invalid argument: $arg"
            print_usage
            ;;
    esac
done

# Deploy using kind if the flag is set
if $deploy_kind; then
    if [[ ! -f "./scripts/deploy-kind.sh" ]]; then
        echo "Error: ./scripts/deploy-kind.sh script is missing."
        exit 1
    fi
    . ./scripts/deploy-kind.sh
fi

# Deploy the demo if the flag is set
if $deploy_demo; then
    if [[ ! -f "./scripts/deploy-demo.sh" ]]; then
        echo "Error: ./scripts/deploy-demo.sh script is missing."
        exit 1
    fi
    . ./scripts/deploy-demo.sh
fi
