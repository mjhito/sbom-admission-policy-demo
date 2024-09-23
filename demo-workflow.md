# Demo workflow

## Prereqs

## Worflow

**Build the Image**
```bash
docker build -t $REGISTRY_USERNAME/snyk-juice-shop:linux-amd64 --platform=linux/amd64 .
```

**Test the Image**
```bash
snyk container test $REGISTRY_USERNAME/snyk-juice-shop:linux-amd64 --platform=linux/amd64
```

**Create an SBOM**
```bash
snyk container sbom $REGISTRY_USERNAME/snyk-juice-shop:linux-am64 --format=spdx2.3+json > bom.spdx.json
```

**Attach the SBOM to the image with ORAS**
```bash
oras attach \
--artifact-type application/spdx+json \
docker.io/"$REGISTRY_USERNAME"/snyk-juice-shop:linux-amd64 \
bom.spdx.json
```

**Inspect the Image**
```bash
oras discover docker.io/$REGISTRY_USERNAME/snyk-juice-shop:linux-amd64
```

**Pull the SBOM**
```bash
oras pull docker.io/$REGISTRY_USERNAME/snyk-juice-shop:sha256-97e7c99eb657bcc631232b747ff7904b2fea40b7301b7c4658e62f6ec6a82dfd
```

**Deploy Gatekeeper/Ratify Constraints**
```bash
kubectl apply -f ./manifests/resources/ 
```