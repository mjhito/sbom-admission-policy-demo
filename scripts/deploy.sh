#!/usr/bin/env bash 
set -eou pipefail
IFS=$'\t'

# shellcheck source=./setenv.sh
source ./setenv.sh

# deploy kind ingress ready cluster with calico CNI and nginx ingress controller

## Deploy kind with no CNI and ingress ports mappings / node-labels

cat <<EOF | kind create cluster --name $CLUSTER_NAME --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    image: kindest/node:v1.28.7@sha256:9bc6c451a289cf96ad0bbaf33d416901de6fd632415b076ab05f5fa7e4f65c58
  - role: worker
    image: kindest/node:v1.28.7@sha256:9bc6c451a289cf96ad0bbaf33d416901de6fd632415b076ab05f5fa7e4f65c58
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"        
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
networking:
  disableDefaultCNI: true
  podSubnet: 10.89.0.0/16
EOF

## deploy the Calico CNI

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml

echo 'waiting for calico pods to become ready....' 
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -A --timeout=90s

## deploy nginx ingress controller

kubectl create ns ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml -n ingress-nginx

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s