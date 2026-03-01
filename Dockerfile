FROM debian:bookworm-slim
WORKDIR /opt/slidebolt
COPY bin/ .build/bin/
EXPOSE 39011
ENTRYPOINT [".build/bin/launcher", "up"]
