FROM golang:1.23-bookworm AS builder
WORKDIR /build

COPY manifest.json .
RUN apt-get update && apt-get install -y jq

RUN mkdir -p /out/bin && \
    jq -c '.[]' manifest.json | while read component; do \
      MODULE=$(echo $component | jq -r '.module'); \
      TAG=$(echo $component | jq -r '.tag'); \
      BINARY=$(echo $component | jq -r '.binary'); \
      echo "Building $BINARY from $MODULE@$TAG..."; \
      GOTOOLCHAIN=auto GOBIN=/out/bin go install $MODULE@$TAG; \
    done

FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends adb && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/slidebolt
COPY --from=builder /out/bin/ .build/bin/
COPY manifest.json .
ARG VERSION=dev
ENV APP_VERSION=$VERSION
EXPOSE 39011
ENTRYPOINT [".build/bin/launcher", "up"]
