FROM debian:bookworm-slim
WORKDIR /opt/slidebolt
COPY bin/ .build/bin/
ARG VERSION=dev
ENV APP_VERSION=$VERSION
EXPOSE 39011
ENTRYPOINT [".build/bin/launcher", "up"]
