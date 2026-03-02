# Release Commands

This repository uses a `Makefile` to manage the Slidebolt release process via GitHub Actions.

| Command | Description |
| :--- | :--- |
| `make release-patch` | Triggers a GitHub Action workflow to create a new **patch** release (e.g., v1.0.1 -> v1.0.2). |
| `make release-minor` | Triggers a GitHub Action workflow to create a new **minor** release (e.g., v1.0.2 -> v1.1.0). |
| `make release-major` | Triggers a GitHub Action workflow to create a new **major** release (e.g., v1.1.0 -> v2.0.0). |

**Note:** These commands require the `gh` (GitHub CLI) tool to be installed and authenticated.
