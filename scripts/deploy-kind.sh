#!/usr/bin/env bash

set -eou pipefail
IFS=$'\t\n'

# Record the start time
start=$(date +%s)
# Detect the OS
OS=$(uname)

# Function to print the usage information and exit the script with a non-zero status
function print_usage {
    echo "Usage: bash deploy-kind.sh"
    echo "$*"
    exit 1
}

if [[ "$OS" = "Darwin" ]]; then
    echo "Deploying Kind cluster with calico CNI and nginx ingress"
    kind create cluster --name "${CLUSTER_NAME:=dev}" --config ./manifests/kind/kind-ingress-arm64.yaml

elif [[ "$OS" = "Linux" ]]; then
    echo "Deploying Kind cluster with calico CNI and nginx ingress"
    kind create cluster --name "${CLUSTER_NAME:=dev}" --config ./manifests/kind/kind-ingress-amd64.yaml

else
    echo "Unsupported OS"
fi


## deploy the Calico CNI

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml

echo 'waiting for calico pods to become ready....' 

kubectl wait --for=condition=ready pod -l k8s-app=calico-node -A --timeout=90s

## Deploy NGINX Ingress Controller
if [[ $OS == "Darwin" ]]; then
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml -n ingress-nginx
elif [[ $OS == "Linux" ]]; then
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml -n ingress-nginx
else
    echo "Unsupported OS: ($OS)"
fi

kubectl wait --namespace ingress-nginx \
--for=condition=ready pod \
--selector=app.kubernetes.io/component=controller \
--timeout=90s

echo "Deployed kind in :" $(( $(date +%s) - start )) "seconds"