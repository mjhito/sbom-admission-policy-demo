# SBOM Admission Policy Demo

A demo of how Gatekeeper/Ratify can be used in conjunction with the Snyk SBOM CLI tools to ensure only images with valid SBOM and Snyk SBOM vulnerability scans are deployed to your kubernetes environment

## Deployment Diagram

TODO

## Why should I care about SBOMs

TODO

## Quick Start

    edit the setenv.sh with the required env vars
    `vi setenv.sh`
    `./scripts/deploy.sh`

    Apply K8s manifests

    `kubectl apply -f ./manifests/verified-deployment.yaml`

    Expected output: "Deployment Created"
   
    `kubectl apply -f ./manifests/unverified-deployment.yaml`

    Expeced output: "Deployment unable to be created: Gatekeeper validation failed: Ratify: No SBOM"

## What is Ratify

Ratify is an open-source project that was established in 2021. It is a verification engine that empowers users to enforce policies through the verification of container images and attestations, such as vulnerability reports and SBOMs (software bills of materials). Ratify offers a pluggable framework that allows users to bring their own verification plugins.

<https://ratify.dev/docs/plugins/verifier/sbom#sbom-with-license-and-package-validation>

One of the primary use cases of Ratify is to use it with Gatekeeper as the Kubernetes policy controller. This helps prevent non-compliant container images from running in your Kubernetes cluster. Ratify acts as an external data provider for Gatekeeper and returns verification data that can be processed by Gatekeeper according to defined policies.

## What is Gatekeeper

Every organization has policies. Some are essential to meet governance and legal requirements. Others help ensure adherence to best practices and institutional conventions. Attempting to ensure compliance manually would be error-prone and frustrating. Automating policy enforcement ensures consistency, lowers development latency through immediate feedback, and helps with agility by allowing developers to operate independently without sacrificing compliance.

Kubernetes allows decoupling policy decisions from the inner workings of the API Server by means of admission controller webhooks, which are executed whenever a resource is created, updated or deleted. Gatekeeper is a validating and mutating webhook that enforces CRD-based policies executed by Open Policy Agent, a policy engine for Cloud Native environments hosted by CNCF as a graduated project.

![gatekeeper/ratify diagram ref:https://techcommunity.microsoft.com/t5/microsoft-developer-community/use-ratify-to-prevent-non-compliant-container-images-from/ba-p/4008730 ](image.png)

### Prerequisites

ORAS - https://oras.land/docs/category/oras-commands/

KIND -

KUBECTL -

SNYK -

### Usage

### Limitations
