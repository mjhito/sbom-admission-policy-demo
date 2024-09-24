## SBOM Admission Policy Demo

This demo showcases how to use [Snyk](snyk.io) container sbom feature alongside [ORAS](oras.land) , Gatekeeper (OPA) and Ratify to ensure that only images with valid SBOMs are deployed to a Kubernetes environments.

The [snyk container sbom](https://docs.snyk.io/snyk-cli/commands/container-sbom) feature generates an SBOM for a container image.

Currently the only supported format is SPDX v2.3 (JSON).

An SBOM can be generated for operating system dependencies as well as [application dependencies within the image](https://docs.snyk.io/scan-with-snyk/snyk-container/use-snyk-container/detect-application-vulnerabilities-in-container-images)

## Workflow Diagram
![image](https://github.com/user-attachments/assets/acffd15a-ee39-4a36-9502-7de6d1b0ef1d)

## Quick Start

### If you have a cluster

1. Edit the `setenv.sh` file to set the required environment variables or ensure they are available in your environment (best practice):

```bash
vi setenv.sh
```

2. Deploy the demo:

```bash
./scripts/deploy.sh --demo
```

3. Run a verified deployment:

```bash
kubectl run verified -n sbom-demo --image=iuriikogan/snyk-juice-shop:linux-amd64
```

Expected Output: `pod/verified created`
Logs for the ratify pod in gatekeeper-system namespace will show:
```markdown
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

4. Test the unverified deployment:

```bash
kubectl run unverified -n sbom-demo --image=iuriikogan/unverified:latest
```

Expected Output:

```Markdown
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: [ratify-constraint] Subject failed verification: docker.io/iuriikogan/unverified@sha256:97396efd3dc2971804148d21cc6a3d532cfd3212c25c10d76664eb8fc56f2878`
```

5. Clean up the environment:
```bash
./scripts/destroy.sh [--kind]
```

### If you don't have a cluster

1. Edit the `setenv.sh` file to set the required environment variables:

```bash
vi setenv.sh
```

2. Deploy the demo:

```bash
./scripts/deploy.sh --all
```

**Continue with step 3 above.**

## Why should I care about SBOMs?

Software Bill of Materials (SBOMs) provide detailed insights into the components within software, offering transparency and accountability. As regulatory frameworks like the NIS Directive (Network and Information Systems) in Europe, the Digital Operational Resilience Act (DORA), and various cybersecurity standards grow increasingly stringent, ensuring compliance is critical for businesses in regulated sectors.

ORAS (OCI Registry As Storage) simplifies SBOM management by allowing SBOMs to be attached directly to OCI container images as artifacts. This enables seamless integration of SBOMs into the software supply chain, ensuring that each image includes a verifiable record of its components. By associating SBOMs with images and enforcing policies that only permit the deployment of images containing SBOMs, organizations can meet regulatory requirements around software transparency and vulnerability management.

Additionally, tools like [Snyk](https://snyk.io) can generate SBOMs for container images and code repositories, providing detailed reports on both open-source dependencies and vulnerabilities in applications. This makes it easier to identify risks early in the development process and maintain security compliance across the entire software stack.

### How ORAS Facilitates SBOM Verification:
ORAS leverages OCI artifact support to store SBOMs alongside container images within OCI-compliant registries. This means that when you push an image, you can also push its associated SBOM as an artifact, enabling SBOM retrieval and verification directly from the registry. This approach ensures that SBOMs are tightly coupled with the software they describe, simplifying compliance with cybersecurity regulations by making SBOM verification part of the deployment process.

### Regulatory Benefits:
- **NIS Directive:** Ensures critical infrastructure operators follow cybersecurity best practices by mandating security incident reporting and proactive risk management, including software transparency through SBOMs.
- **DORA:** Focuses on resilience in the financial sector’s IT systems by requiring secure software deployment practices, including SBOMs for tracking software vulnerabilities.
- **Other Cybersecurity Regulations:** Similar regulations (e.g., Executive Order 14028 in the U.S.) require SBOM adoption to enhance software supply chain security.

## Why Should I integrate SBOMs into my container deployment pipelines/enforce SBOMs via policy?

Integrating SBOMs into your container deployment pipelines ensures that every image has passed critical security and compliance checks. With tools like ORAS, you can attach SBOMs directly to your OCI images, enabling automated verification before deployment. This helps identify vulnerabilities early, protects against attacks, and provides an auditable trail that demonstrates compliance during security audits.

By using solutions like [Snyk](https://snyk.io), which generates SBOMs for both containers and applications, you can further enhance security across the entire software lifecycle. Snyk integrates with container registries and CI/CD pipelines to scan images for known vulnerabilities and ensure that your SBOMs are always up-to-date with the latest security information.

Using policy enforcement tools like Gatekeeper and Ratify ensures that only images with valid SBOMs and no unresolved vulnerabilities are deployed. This approach automates compliance, facilitates audit-readiness, and ensures adherence to regulatory frameworks during audits and reviews.

## What is ORAS?

[ORAS](https://oras.land) (OCI Registry As Storage) is an open-source project that allows users to store various types of artifacts—beyond just container images—in OCI-compliant registries. ORAS enables developers to attach additional metadata, such as SBOMs, signatures, or documentation, directly to container images by leveraging the OCI Artifact standard. This makes ORAS a powerful tool for managing software artifacts throughout the entire development and deployment lifecycle.

By supporting the attachment of SBOMs as OCI artifacts, ORAS makes it easier for organizations to maintain transparency and security across their software supply chain. This simplifies SBOM management, ensuring that the artifacts and images stored in registries have all relevant metadata in place, enhancing compliance and operational resilience.

## What is Gatekeeper?

Gatekeeper is a policy enforcement tool for Kubernetes that ensures resources comply with organizational policies. It automates policy enforcement, minimizing errors and enhancing consistency by providing immediate feedback during development.

Kubernetes’ policy enforcement is decoupled from its API server using admission controller webhooks that are triggered when resources are created, updated, or deleted. Gatekeeper acts as a validating and mutating webhook, enforcing Custom Resource Definitions (CRDs) defined by the Open Policy Agent (OPA), a powerful policy engine for cloud-native environments.

## What is Ratify?

Ratify, established in 2021, is an open-source verification engine that allows users to enforce policies by verifying container images and attestations, including SBOMs and vulnerability reports. Ratify offers a pluggable framework, enabling integration with custom verification plugins.

A common use case for Ratify is integrating it with Gatekeeper as a Kubernetes policy controller. By using ORAS to attach SBOMs to OCI images and Ratify to verify these SBOMs, organizations can automate security and compliance checks in real-time, preventing the deployment of non-compliant images.

[Learn more about Ratify and SBOM verification](https://ratify.dev/docs/plugins/verifier/sbom#sbom-with-license-and-package-validation).

## Prerequisites

Ensure the following tools are installed:

- [docker](https://docs.docker.com/engine/install/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm](https://helm.sh/docs/intro/install/)
  
## Limitations

TODO
