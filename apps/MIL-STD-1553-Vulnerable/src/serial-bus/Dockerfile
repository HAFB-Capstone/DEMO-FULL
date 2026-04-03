FROM python:3.11-slim

WORKDIR /app

# Copy submodule and source
COPY ./simulator ./simulator
COPY ./src ./src

# Hardening: Remove the shell so players can't log in
RUN rm /bin/sh /bin/bash

# Run as non-privileged user
USER 1000

ENTRYPOINT ["python", "src/run.py"]