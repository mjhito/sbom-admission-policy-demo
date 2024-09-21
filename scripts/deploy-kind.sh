#!/usr/bin/env bash

set -eou pipefail
IFS=$'\t\n'

start=$(date +%s)

# Function to print the usage information and exit the script with a non-zero status
function print_usage {
    echo "Usage: bash deploy-kind.sh"
    echo "$*"
    exit 1
}

echo "Deploying Kind cluster with calico cni and nginx ingress"
kind create cluster --name "$CLUSTER_NAME" --config ./manifests/resources/kind-ingress.yaml

## deploy the Calico CNI

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml

echo 'waiting for calico pods to become ready....' 

kubectl wait --for=condition=ready pod -l k8s-app=calico-node -A --timeout=90s

## deploy nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml -n ingress-nginx

kubectl wait --namespace ingress-nginx \
--for=condition=ready pod \
--selector=app.kubernetes.io/component=controller \
--timeout=90s

echo "Deployed kind in :" $(( $(date +%s) - $start )) "seconds"