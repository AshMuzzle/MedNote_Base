#!/bin/bash
set -e

ollama pull llama3.2:3b-instruct-fp16
ollama pull llama3.1:8b-instruct-q6_K
ollama serve & sleep 3

wait