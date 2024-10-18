package main

import (
	"context"
	"flag"
	"os"

	v1 "github.com/opencontainers/image-spec/specs-go/v1"
	oras "oras.land/oras-go/v2"
	"oras.land/oras-go/v2/content/file"
	"oras.land/oras-go/v2/registry/remote"
	"oras.land/oras-go/v2/registry/remote/auth"
	"oras.land/oras-go/v2/registry/remote/retry"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

func main() {
	// Initialize the logger
	logger, err := zap.NewDevelopment()
	if err != nil {
		// Handle logger initialization errors appropriately
		logger.Fatal("Failed to initialize logger:", err)
	}
	defer logger.Sync() // Ensure logs are flushed

	// Define flags for the inputs
	sbom := flag.String("sbom", "", "Path to the SBOM file (required)")
	registryURL := flag.String("registry", "", "Registry URL (required)")
	registryUsername := flag.String("registry-username", "", "Registry username (required)")
	registryPassword := flag.String("registry-password", "", "Registry password (required)")
	imageTag := flag.String("image-tag", "", "Image tag in the form of 'repository:tag' (required)")

	flag.Parse()

	// Check if all flags are provided
	if *sbom == "" || *registryURL == "" || *registryUsername == "" || *registryPassword == "" || *imageTag == "" {
		logger.Error("Error: all flags --sbom, --registry, --registry-username, --registry-password, and --image-tag are required.")
		flag.Usage()
		os.Exit(1)
	}

	// 0. Create a file store for SBOM
	fs, err := file.New("/tmp/")
	if err != nil {
		logger.Fatal("Error creating file store:", err)
	}
	defer fs.Close()

	ctx := context.Background()

	// 1. Check if SBOM file exists
	if _, err := os.Stat(*sbom); os.IsNotExist(err) {
		logger.Fatal("Error: SBOM file", *sbom, "does not exist.")
	}

	// 2. Add SBOM file to the file store
	mediaType := "application/spdx+json" // SBOM artifact type
	fileName := *sbom
	fileDescriptor, err := fs.Add(ctx, fileName, mediaType, "")
	if err != nil {
		logger.Fatal("Error adding SBOM to file store:", err)
	}
	logger.Info("File descriptor for SBOM:", zap.String("file_descriptor", fileDescriptor))

	// 3. Pack the SBOM file into a manifest
	artifactType := "application/spdx+json" // Define the artifact type
	opts := oras.PackManifestOptions{
		Layers: []v1.Descriptor{fileDescriptor},
	}
	manifestDescriptor, err := oras.PackManifest(ctx, fs, oras.PackManifestVersion1_1, artifactType, opts)
	if err != nil {
		logger.Fatal("Error packing SBOM manifest:", err)
	}
	logger.Info("Manifest descriptor:", zap.String("manifest_descriptor", manifestDescriptor))

	tag := *imageTag
	if err = fs.Tag(ctx, manifestDescriptor, tag); err != nil {
		logger.Fatal("Error tagging SBOM manifest:", err)
	}

	// 4. Connect to the remote repository
	repo, err := remote.NewRepository(*registryURL)
	if err != nil {
		logger.Fatal("Error creating remote repository:", err)
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

	// 5. Copy the SBOM from the file store to the remote repository
	_, err = oras.Copy(ctx, fs, tag, repo, tag, oras.DefaultCopyOptions)
	if err != nil {
		logger.Fatal("Error copying SBOM to remote repository:", err)
	}

	logger.Info("SBOM successfully attached to the image.")
}
