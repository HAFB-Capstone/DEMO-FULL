FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

# Copy tools
COPY *.py .

# Make scripts executable
RUN chmod +x *.py

CMD ["/bin/bash"]
