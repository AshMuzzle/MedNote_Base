#!/bin/bash
set -e

# Function to health check Ollama.
wait_for_ollama() {
    until curl -s http://localhost:11434/v1/models > /dev/null; do
        echo "Waiting for Ollama server to start..."
        sleep 2
    done
    echo "Ollama server is ready."
}

# Adapt to GPU presence.
if command -v nvidia-smi &> /dev/null && nvidia-smi -L | grep -q "GPU"; then
    echo "GPU detected. Selecting larger model."
    SELECTED_MODEL="llama3.1:8b-instruct-q6_K"
else
    echo "No GPU detected. Selecting smaller model."
    SELECTED_MODEL="llama3.2:3b-instruct-fp16"
fi

# Verify model directory.
# mkdir -p /app/source/models

# Set LLM.
echo "SELECTED_MODEL=$SELECTED_MODEL" > /app/source/models/model.env

# Start service.
ollama serve &
OLLAMA_PID=$!

# Verify service.
wait_for_ollama

# Get LLM.
if ollama list | grep -q "$SELECTED_MODEL"; then
    echo "Model $SELECTED_MODEL already exists locally. Skipping pull."
else
    echo "Pulling model: $SELECTED_MODEL"
    ollama pull "$SELECTED_MODEL"
fi

# Continue service.
wait $OLLAMA_PID