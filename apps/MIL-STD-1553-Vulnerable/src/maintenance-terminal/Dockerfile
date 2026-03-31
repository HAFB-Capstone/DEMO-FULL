FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# The routine script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Run as non-privileged user (simulating the logged-in user)
RUN useradd -m maintenance
USER maintenance

CMD ["/app/entrypoint.sh"]
