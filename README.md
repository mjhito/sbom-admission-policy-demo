# sbom-admission-policy-demo

A demo repo to showcase how Gatekeeper/Ratify can be used in conjunction with the Snyk SBOM CLI tools to ensure only images with valid SBOM and Snyk SBOM vulnerability scans are deployed to your kubernetes environment

## example implementation

Ratify is an open-source project that was established in 2021. It is a verification engine that empowers users to enforce policies through the verification of container images and attestations, such as vulnerability reports and SBOMs (software bills of materials). Ratify offers a pluggable framework that allows users to bring their own verification plugins.

<https://ratify.dev/docs/plugins/verifier/sbom#sbom-with-license-and-package-validation>

One of the primary use cases of Ratify is to use it with Gatekeeper as the Kubernetes policy controller. This helps prevent non-compliant container images from running in your Kubernetes cluster. Ratify acts as an external data provider for Gatekeeper and returns verification data that can be processed by Gatekeeper according to defined policies.
