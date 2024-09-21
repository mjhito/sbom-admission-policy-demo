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
    local required_vars=("ENV_VAR1" "ENV_VAR2") # Replace with actual required env vars
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "Error: Required environment variable $var is not set."
            exit 1
        fi
    done
}

# Call the function to check env vars
check_env_vars

# Check if the --kind flag is set
if [[ "$1" == "--kind" ]]; then
    if [[ ! -f "./scripts/deploy-kind.sh" ]]; then
        echo "Error: ./scripts/deploy-kind.sh script is missing."
        exit 1
    fi
    . ./scripts/deploy-kind.sh
fi

# Check if the --demo flag is set
if [[ "$2" == "--demo" ]]; then
    if [[ ! -f "./scripts/deploy-demo.sh" ]]; then
        echo "Error: ./scripts/deploy-demo.sh script is missing."
        exit 1
    fi
    . ./scripts/deploy-demo.sh
fi

