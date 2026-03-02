### `release` repository

#### Project Overview

This repository is responsible for building and releasing the Slidebolt application. It contains the necessary files to create a Docker image for the release and trigger release workflows.

#### Architecture

The release process is containerized using Docker. The `Dockerfile` specifies a Debian-based image that runs a launcher application. The version of the application is managed via a `VERSION` file and passed as a build argument to the Docker image.

#### Key Files

| File | Description |
| :--- | :--- |
| `Dockerfile` | Defines the Docker image for the release, based on `debian:bookworm-slim`. |
| `Makefile` | Contains commands to trigger GitHub Actions workflows for creating new releases (patch, minor, major). |
| `VERSION` | Stores the current version of the release. |

#### Available Commands

The following commands are available in the `Makefile` to trigger release workflows:

| Command | Description |
| :--- | :--- |
| `make release-patch` | Triggers a new patch release. |
| `make release-minor` | Triggers a new minor release. |
| `make release-major` | Triggers a new major release. |
