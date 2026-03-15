//go:build mage
package main

import (
	"fmt"

	"github.com/magefile/mage/sh"
)

// ReleasePatch triggers a patch release workflow on GitHub.
func ReleasePatch() error {
	return sh.Run("gh", "workflow", "run", "release.yml", "--repo", "slidebolt/release", "-f", "bump=patch")
}

// ReleaseMinor triggers a minor release workflow on GitHub.
func ReleaseMinor() error {
	return sh.Run("gh", "workflow", "run", "release.yml", "--repo", "slidebolt/release", "-f", "bump=minor")
}

// ReleaseMajor triggers a major release workflow on GitHub.
func ReleaseMajor() error {
	return sh.Run("gh", "workflow", "run", "release.yml", "--repo", "slidebolt/release", "-f", "bump=major")
}

// ReleaseAllPatch runs the local release-all script for patch bumps.
func ReleaseAllPatch() error {
	return sh.Run("./scripts/release-all.sh", "patch")
}

// FeatureStart begins a new feature branch.
func FeatureStart(branch string) error {
	if branch == "" {
		return fmt.Errorf("branch name required")
	}
	return sh.Run("./scripts/feature-start.sh", branch)
}

// FeatureFinish completes a feature branch.
func FeatureFinish(branch string) error {
	if branch == "" {
		return fmt.Errorf("branch name required")
	}
	return sh.Run("./scripts/feature-finish.sh", branch)
}
