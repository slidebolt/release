package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

type source struct {
	Repository string `json:"repository"`
	Asset      string `json:"asset"`
}

type manifest struct {
	Manager    source   `json:"manager"`
	Components []source `json:"components"`
}

type artifact struct {
	URL    string `json:"url"`
	SHA256 string `json:"sha256"`
}

type hello struct {
	ID        string          `json:"id"`
	Kind      string          `json:"kind"`
	DependsOn []string        `json:"dependsOn,omitempty"`
	Setup     json.RawMessage `json:"setup"`
}

type component struct {
	ID        string              `json:"id"`
	Version   string              `json:"version"`
	Kind      string              `json:"kind"`
	DependsOn []string            `json:"dependsOn,omitempty"`
	Setup     json.RawMessage     `json:"setup"`
	Artifacts map[string]artifact `json:"artifacts"`
}

type catalog struct {
	SchemaVersion int                 `json:"schemaVersion"`
	Release       string              `json:"release"`
	Manager       map[string]artifact `json:"manager"`
	Components    []component         `json:"components"`
}

func main() {
	manifestPath := flag.String("manifest", "quickstart-components.json", "component composition manifest")
	versionsPath := flag.String("versions", "versions.env", "released component versions")
	outputPath := flag.String("output", "quickstart-catalog.json", "output catalog")
	release := flag.String("release", "development", "delivery release name")
	flag.Parse()
	if err := run(*manifestPath, *versionsPath, *outputPath, *release); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(manifestPath, versionsPath, outputPath, release string) error {
	var definition manifest
	if err := readJSON(manifestPath, &definition); err != nil {
		return err
	}
	versions, err := readVersions(versionsPath)
	if err != nil {
		return err
	}
	temporary, err := os.MkdirTemp("", "slidebolt-catalog-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(temporary)

	managerArtifacts, _, err := resolveArtifacts(context.Background(), temporary, definition.Manager, versions[definition.Manager.Repository])
	if err != nil {
		return fmt.Errorf("manager: %w", err)
	}
	result := catalog{SchemaVersion: 2, Release: release, Manager: managerArtifacts}
	seen := map[string]bool{}
	for _, item := range definition.Components {
		version := versions[item.Repository]
		artifacts, executable, err := resolveArtifacts(context.Background(), temporary, item, version)
		if err != nil {
			return fmt.Errorf("%s: %w", item.Repository, err)
		}
		manifest, err := inspect(executable)
		if err != nil {
			return fmt.Errorf("%s: %w", item.Repository, err)
		}
		if seen[manifest.ID] {
			return fmt.Errorf("duplicate component id %q", manifest.ID)
		}
		seen[manifest.ID] = true
		result.Components = append(result.Components, component{ID: manifest.ID, Version: version, Kind: manifest.Kind, DependsOn: manifest.DependsOn, Setup: manifest.Setup, Artifacts: artifacts})
	}
	for _, item := range result.Components {
		for _, dependency := range item.DependsOn {
			if !seen[dependency] {
				return fmt.Errorf("%s depends on absent component %s", item.ID, dependency)
			}
		}
	}
	sort.Slice(result.Components, func(i, j int) bool { return result.Components[i].ID < result.Components[j].ID })
	raw, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(outputPath, append(raw, '\n'), 0644)
}

func resolveArtifacts(ctx context.Context, temporary string, item source, version string) (map[string]artifact, string, error) {
	if item.Repository == "" || item.Asset == "" || version == "" {
		return nil, "", fmt.Errorf("incomplete source or missing version")
	}
	artifacts := map[string]artifact{}
	var executable string
	for _, platform := range []string{"linux_amd64", "linux_arm64"} {
		url := fmt.Sprintf("https://github.com/slidebolt/%s/releases/download/%s/%s_%s", item.Repository, version, item.Asset, platform)
		path := filepath.Join(temporary, item.Repository+"_"+platform)
		sum, err := download(ctx, url, path)
		if err != nil {
			return nil, "", err
		}
		artifacts[platform] = artifact{URL: url, SHA256: sum}
		if platform == "linux_amd64" {
			executable = path
		}
	}
	return artifacts, executable, nil
}

func download(ctx context.Context, url, destination string) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, 2*time.Minute)
	defer cancel()
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", err
	}
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		return "", err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return "", fmt.Errorf("GET %s: HTTP %d", url, response.StatusCode)
	}
	file, err := os.OpenFile(destination, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0700)
	if err != nil {
		return "", err
	}
	hash := sha256.New()
	_, copyErr := io.Copy(io.MultiWriter(file, hash), io.LimitReader(response.Body, 1<<30))
	closeErr := file.Close()
	if copyErr != nil {
		return "", copyErr
	}
	if closeErr != nil {
		return "", closeErr
	}
	return hex.EncodeToString(hash.Sum(nil)), nil
}

func inspect(path string) (hello, error) {
	output, err := exec.Command(path, "hello").Output()
	if err != nil {
		return hello{}, err
	}
	var result hello
	if err := json.Unmarshal(output, &result); err != nil {
		return hello{}, err
	}
	if result.ID == "" || result.Kind == "" || len(result.Setup) == 0 || string(result.Setup) == "null" {
		return hello{}, fmt.Errorf("hello response has no serialized setup definition")
	}
	return result, nil
}

func readJSON(path string, target any) error {
	raw, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	return json.Unmarshal(raw, target)
}

func readVersions(path string) (map[string]string, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	result := map[string]string{}
	for _, line := range strings.Split(string(raw), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, value, ok := strings.Cut(line, "=")
		if !ok || key == "" || value == "" {
			return nil, fmt.Errorf("invalid versions line %q", line)
		}
		result[key] = value
	}
	return result, nil
}
