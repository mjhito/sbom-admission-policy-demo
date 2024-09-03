#!/usr/bin/env bash 
set -eou pipefail
IFS=$'\t'

# shellcheck source=./setenv.sh
source ./setenv.sh

# deploy kind ingress ready cluster with calico CNI and nginx ingress controller

## Deploy kind with no CNI and ingress ports mappings / node-labels

kind create cluster --name "$CLUSTER_NAME" --config ./kind-ingress.yaml

## deploy the Calico CNI

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml

echo 'waiting for calico pods to become ready....' 
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -A --timeout=90s

## Deploy gatekeeper
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts

helm install gatekeeper/gatekeeper  \
    --name-template=gatekeeper \
    --namespace gatekeeper-system --create-namespace \
    --set enableExternalData=true \
    --set validatingWebhookTimeoutSeconds=5 \
    --set mutatingWebhookTimeoutSeconds=2 \
    --set externaldataProviderResponseCacheTTL=10s