.PHONY: release-patch release-minor release-major release-all-patch release-all-minor release-all-major

release-patch:
	gh workflow run release.yml --repo slidebolt/release -f bump=patch

release-minor:
	gh workflow run release.yml --repo slidebolt/release -f bump=minor

release-major:
	gh workflow run release.yml --repo slidebolt/release -f bump=major

release-all-patch:
	./scripts/release-all.sh patch

release-all-minor:
	./scripts/release-all.sh minor

release-all-major:
	./scripts/release-all.sh major
