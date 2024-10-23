package main

import (
	"context"
	"flag"
	"os"

	v1 "github.com/opencontainers/image-spec/specs-go/v1"
	"golang.org/x/exp/slog"
	oras "oras.land/oras-go/v2"
	"oras.land/oras-go/v2/content/file"
	"oras.land/oras-go/v2/registry/remote"
	"oras.land/oras-go/v2/registry/remote/auth"
	"oras.land/oras-go/v2/registry/remote/retry"
)

// getEnvOrFlag checks if an environment variable is set and returns its value,
// otherwise falls back to the provided flag value.
func getEnvOrFlag(envVar, flagValue string) string {
	if value, exists := os.LookupEnv(envVar); exists {
		return value
	}
	return flagValue
}

func main() {
	// Initialize the logger
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		AddSource: true,
		Level:     slog.LevelDebug,
	}))

	// Define flags for the inputs
	sbom := flag.String("sbom", "", "Path to the SBOM file (required)")
	registryURL := flag.String("registry", "", "Registry URL (required)")
	registryUsername := flag.String("registry-username", "", "Registry username (required)")
	registryPassword := flag.String("registry-password", "", "Registry password (required)")
	imageTag := flag.String("image-tag", "", "Image tag in the form of 'repository:tag' (required)")

	flag.Parse()

	// Fetch values from environment variables or fall back to flags
	sbomFile := getEnvOrFlag("SBOM_FILE", *sbom)
	registry := getEnvOrFlag("REGISTRY_URL", *registryURL)
	username := getEnvOrFlag("REGISTRY_USERNAME", *registryUsername)
	password := getEnvOrFlag("REGISTRY_PASSWORD", *registryPassword)
	tag := getEnvOrFlag("IMAGE_TAG", *imageTag)

	// Check if all required inputs are provided
	if sbomFile == "" || registry == "" || username == "" || password == "" || tag == "" {
		logger.Error("Error: missing required inputs. You must set the environment variables or provide flags for --sbom, --registry, --registry-username, --registry-password, and --image-tag.")
		flag.Usage()
		os.Exit(1)
	}

	// 0. Create a file store for SBOM
	fs, err := file.New("/tmp/")
	if err != nil {
		logger.Error("Error creating file store", slog.Any("error", err))
		os.Exit(1)
	}
	defer fs.Close()

	ctx := context.Background()

	// 1. Check if SBOM file exists
	if _, err := os.Stat(sbomFile); os.IsNotExist(err) {
		logger.Error("Error: SBOM file does not exist", slog.String("sbom", sbomFile))
		os.Exit(1)
	}

	// 2. Add SBOM file to the file store
	mediaType := "application/spdx+json" // SBOM artifact type
	fileDescriptor, err := fs.Add(ctx, sbomFile, mediaType, "")
	if err != nil {
		logger.Error("Error adding SBOM to file store", slog.Any("error", err))
		os.Exit(1)
	}
	logger.Info("File descriptor for SBOM", slog.Any("file_descriptor", fileDescriptor))

	// 3. Pack the SBOM file into a manifest
	artifactType := "application/spdx+json" // Define the artifact type
	opts := oras.PackManifestOptions{
		Layers: []v1.Descriptor{fileDescriptor},
	}
	manifestDescriptor, err := oras.PackManifest(ctx, fs, oras.PackManifestVersion1_1, artifactType, opts)
	if err != nil {
		logger.Error("Error packing SBOM manifest", slog.Any("error", err))
		os.Exit(1)
	}
	logger.Info("Manifest descriptor", slog.Any("manifest_descriptor", manifestDescriptor))

	if err = fs.Tag(ctx, manifestDescriptor, tag); err != nil {
		logger.Error("Error tagging SBOM manifest", slog.Any("error", err))
		os.Exit(1)
	}

	// 4. Connect to the remote repository
	repo, err := remote.NewRepository(registry)
	if err != nil {
		logger.Error("Error creating remote repository", slog.Any("error", err))
		os.Exit(1)
	}

	// Use authentication if provided
	repo.Client = &auth.Client{
		Client: retry.DefaultClient,
		Cache:  auth.NewCache(),
		Credential: auth.StaticCredential(registry, auth.Credential{
			Username: username,
			Password: password,
		}),
	}

	// 5. Copy the SBOM from the file store to the remote repository
	_, err = oras.Copy(ctx, fs, tag, repo, tag, oras.DefaultCopyOptions)
	if err != nil {
		logger.Error("Error copying SBOM to remote repository", slog.Any("error", err))
		os.Exit(1)
	}

	logger.Info("SBOM successfully attached to the image.")
}
