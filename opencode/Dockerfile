# OpenCode, contained. It has no access to the host, and its only way to affect the
# world is the SlideBolt MCP server it is given.
FROM node:22-slim
RUN npm install -g opencode-ai@1.17.11 && useradd --create-home agent && mkdir /workspace && chown agent /workspace
# Conversation history lives in $XDG_DATA_HOME/opencode. Created here, owned by
# the agent, so a new volume mounted on it starts with the right owner.
RUN mkdir -p /data/opencode && chown -R agent /data
ENV XDG_DATA_HOME=/data
COPY opencode.json AGENTS.md /workspace/
USER agent
WORKDIR /workspace
ENV OPENCODE_DISABLE_AUTOUPDATE=true
EXPOSE 4096
ENTRYPOINT ["opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]
