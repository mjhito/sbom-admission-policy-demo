#!/usr/bin/env bash

# Exit the script on any error, unset variable, or command failure in a pipeline.
set -eou pipefail
IFS=$'\n\t'

# Deploy Artifactory
echo "=== Deploying Artifactory ==="

# Create namespace
kubectl create namespace artifactory || echo "Namespace 'artifactory' already exists, continuing..."

# Add JFrog Helm chart repository
helm repo add jfrog https://charts.jfrog.io
helm repo update

# Create a master key
export MASTER_KEY=$(openssl rand -hex 32)
echo "Master key generated: ${MASTER_KEY}"

# Create a secret containing the master key
kubectl create secret generic my-masterkey-secret -n artifactory --from-literal=master-key="${MASTER_KEY}" || \
echo "Secret 'my-masterkey-secret' already exists, continuing..."

# Create a key
export JOIN_KEY=$(openssl rand -hex 32)
echo ${JOIN_KEY}

# Create a key
export JOIN_KEY=$(openssl rand -hex 32)
echo ${JOIN_KEY}
 
# Create a secret containing the key. The key in the secret must be named join-key
kubectl create secret generic my-joinkey-secret -n artifactory --from-literal=join-key=${JOIN_KEY}

# Helm upgrade/install Artifactory
helm upgrade --install artifactory jfrog/artifactory -n artifactory \
  --set artifactory.masterKey="${MASTER_KEY}" \
  --set artifactory.masterKeySecretName=my-masterkey-secret \
  --set artifactory.adminPassword=password \
  --set service.type=ClusterIP \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.host="artifactory.localhost" \
  --namespace artifactory --create-namespace

# Wait for Artifactory pods to be ready (increase timeout if needed)
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=artifactory -n artifactory --timeout=300s

# Get the ingress host
ARTIFACTORY_URL=$(kubectl get ingress -n artifactory -o jsonpath='{.spec.rules[*].host}' | tr -d '[]')
ARTIFACTORY_LICENSE=$(kubectl get secret -n artifactory -o jsonpath='{.data.license}' | base64 --decode)
echo "Artifactory URL: ${ARTIFACTORY_URL}"
echo "Artifactory Licensr: ${ARTIFACTORY_LICENSE}"


# Output deployment information
echo "Artifactory admin password is set to 'password'"
echo "Artifactory is now accessible at https://${ARTIFACTORY_URL}"
