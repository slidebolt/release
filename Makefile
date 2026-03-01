.PHONY: release-patch release-minor release-major

release-patch:
	gh workflow run release.yml --repo slidebolt/release -f bump=patch

release-minor:
	gh workflow run release.yml --repo slidebolt/release -f bump=minor

release-major:
	gh workflow run release.yml --repo slidebolt/release -f bump=major
