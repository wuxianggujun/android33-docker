FROM node:18-bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Minimal native build tooling for compiling Node.js dependencies (SRP + YAGNI)
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["bash"]
