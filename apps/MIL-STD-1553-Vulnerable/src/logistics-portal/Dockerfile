FROM python:3.11-slim

WORKDIR /app

# Install Flask
RUN pip install --no-cache-dir flask

# 1. Create the 'Vault Bridge' infrastructure
# This is where the maintenance tools live. 
# We make it globally writable to allow the Path Traversal overwrite.
RUN mkdir -p /opt/hafb/tools && chmod 777 /opt/hafb/tools

# 2. Create the web app structure
COPY . .
RUN mkdir -p /app/uploads && chmod 777 /app/uploads

# 3. Pre-place the 'legitimate' tool that the Red Team will overwrite
# This ensures the tool is there to be 'hijacked'
RUN echo '#!/bin/bash\necho "Standard Maintenance Sync Active"' > /opt/hafb/tools/bus_controller.sh \
    && chmod +x /opt/hafb/tools/bus_controller.sh

# Unlike the flight computer, we KEEP the shell here 
# so the Red Team can get a reverse shell.
# We also need 'curl' or 'nc' for some of the lateral movement demos
RUN apt-get update && apt-get install -y curl netcat-openbsd && rm -rf /var/lib/apt/lists/*

EXPOSE 8080

ENTRYPOINT ["python", "app.py"]