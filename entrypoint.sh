#!/bin/bash
set -e

# Adapt to GPU presence.
if command -v nvidia-smi &> /dev/null && nvidia-smi -L | grep -q "GPU"; then
    echo "GPU detected. Selecting larger model."
    SELECTED_MODEL="llama3.1:8b-instruct-q6_K"
else
    echo "No GPU detected. Selecting smaller model."
    SELECTED_MODEL="llama3.2:3b-instruct-fp16"
fi

# Update environment model.
echo "SELECTED_MODEL=$SELECTED_MODEL" > ../.env

# Pull the selected model.
ollama pull "$SELECTED_MODEL"

# Start and keep alive Ollama.
ollama serve & sleep 5
wait
