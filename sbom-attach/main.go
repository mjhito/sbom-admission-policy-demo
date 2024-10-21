package main

import (
	"context"
	"flag"
	"fmt"
	"os"

	v1 "github.com/opencontainers/image-spec/specs-go/v1"
	oras "oras.land/oras-go/v2"
	"oras.land/oras-go/v2/content/file"
	"oras.land/oras-go/v2/registry/remote"
	"oras.land/oras-go/v2/registry/remote/auth"
	"oras.land/oras-go/v2/registry/remote/retry"
)

func main() {
	// Define flags for the inputs
	sbom := flag.String("sbom", "", "Path to the SBOM file (required)")
	registryURL := flag.String("registry", "", "Registry URL (required)")
	registryUsername := flag.String("registry-username", "", "Registry username (required)")
	registryPassword := flag.String("registry-password", "", "Registry password (required)")
	imageTag := flag.String("image-tag", "", "Image tag in the form of 'repository:tag' (required)")

	flag.Parse()

	// Check if all flags are provided
	if *sbom == "" || *registryURL == "" || *registryUsername == "" || *registryPassword == "" || *imageTag == "" {
		fmt.Println("Error: all flags --sbom, --registry, --registry-username, --registry-password, and --image-tag are required.")
		flag.Usage()
		os.Exit(1)
	}

	// 0. Create a file store for SBOM
	fs, err := file.New("/tmp/")
	if err != nil {
		panic(err)
	}
	defer fs.Close()

	ctx := context.Background()

	// 1. Add SBOM file to the file store
	mediaType := "application/spdx+json" // SBOM artifact type
	fileName := *sbom
	fileDescriptor, err := fs.Add(ctx, fileName, mediaType, "")
	if err != nil {
		panic(err)
	}
	fmt.Printf("File descriptor for SBOM: %v\n", fileDescriptor)

	// 2. Pack the SBOM file into a manifest
	artifactType := "application/spdx+json" // Define the artifact type
	opts := oras.PackManifestOptions{
		Layers: []v1.Descriptor{fileDescriptor},
	}
	manifestDescriptor, err := oras.PackManifest(ctx, fs, oras.PackManifestVersion1_1, artifactType, opts)
	if err != nil {
		panic(err)
	}
	fmt.Printf("Manifest descriptor: %v\n", manifestDescriptor)

	tag := *imageTag
	if err = fs.Tag(ctx, manifestDescriptor, tag); err != nil {
		panic(err)
	}

	// 3. Connect to the remote repository
	repo, err := remote.NewRepository(*registryURL)
	if err != nil {
		panic(err)
	}

	// Use authentication if provided
	repo.Client = &auth.Client{
		Client: retry.DefaultClient,
		Cache:  auth.NewCache(),
		Credential: auth.StaticCredential(*registryURL, auth.Credential{
			Username: *registryUsername,
			Password: *registryPassword,
		}),
	}

	// 4. Copy the SBOM from the file store to the remote repository
	_, err = oras.Copy(ctx, fs, tag, repo, tag, oras.DefaultCopyOptions)
	if err != nil {
		panic(err)
	}

	fmt.Println("SBOM successfully attached to the image.")
}
