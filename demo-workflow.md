# Demo workflow

## Prereqs

## Worflow

**Build the Image**

```bash
docker build -t $REGISTRY_USERNAME/snyk-juice-shop:linux-amd64 --platform=linux/amd64 . --push
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
oras pull docker.io/$REGISTRY_USERNAME/snyk-juice-shop@$SBOM_SHA
```

**Run the verified deployment**

```bash
kubectl run verified -n sbom-demo --image=iuriikogan/snyk-juice-shop:linux-amd64
```

Expected Output: `pod/verified created`
Show logs on Ratify pod in Gatekeeper-System namespace

```Markdown
{
    "subject": "docker.io/iuriikogan/snyk-juice-shop@sha256:97e7c99eb657bcc631232b747ff7904b2fea40b7301b7c4658e62f6ec6a82dfd",
    "referenceDigest": "sha256:05149e16a75f5667d31906b1aa595c9dca6947c79a3de904292b513cbc6ea400",
    "artifactType": "application/spdx+json",
    "verifierReports": [
    {
        "isSuccess": true,
        "message": "SBOM verification success. No license or package violation found.",
        "name": "verifier-sbom",
        "verifierName": "verifier-sbom",
        "type": "sbom",
        "verifierType": "sbom",
        "extensions": {
        "creationInfo": {
            "created": "2024-09-23T13:43:58Z",
            "creators": [
            "Tool: Snyk SBOM Export API v1.98.0",
            "Organization: Snyk"
            ],
            "licenseListVersion": "3.19"
        }
        }
    }
    ],
    "nestedReports": []
}
```

**Run the unverified deployment**

```bash
kubectl run unverified -n sbom-demo --image=iuriikogan/unverified:latest
```

Expected Output: `Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: [ratify-constraint] Subject failed verification: docker.io/iuriikogan/unverified`
