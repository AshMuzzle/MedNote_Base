FROM nvidia/cuda:12.6.2-cudnn-runtime-ubuntu22.04

WORKDIR /ollama

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    curl -fsSL https://ollama.com/install.sh | sh && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]