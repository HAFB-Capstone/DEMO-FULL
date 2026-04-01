# Build requires network (pinned release downloads). Runtime lab is CLI-only; bind-mount /lab at run time.
FROM debian:bookworm-slim

ARG SYFT_VERSION=1.23.1
ARG JQ_VERSION=1.7
# Bump these when changing SYFT_VERSION / JQ_VERSION (verify against official release assets).
ARG SYFT_TAR_SHA256=42f3e01b64f054d0caee42073cb94e3ac3e61be6f0100e7ecda96e6a2abf7e22
ARG JQ_BIN_SHA256=2f312b9587b1c1eddf3a53f9a0b7d276b9b7b94576c85bda22808ca950569716

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    gzip \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fsSL "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz" -o /tmp/syft.tgz; \
    echo "${SYFT_TAR_SHA256}  /tmp/syft.tgz" | sha256sum -c -; \
    tar -xzf /tmp/syft.tgz -C /usr/local/bin syft; \
    chmod +x /usr/local/bin/syft; \
    rm -f /tmp/syft.tgz

RUN set -eux; \
    curl -fsSL "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64" -o /usr/local/bin/jq; \
    echo "${JQ_BIN_SHA256}  /usr/local/bin/jq" | sha256sum -c -; \
    chmod +x /usr/local/bin/jq

WORKDIR /lab
