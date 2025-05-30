#!/bin/bash
echo "Starting text-generation-webui server with official launcher..."
echo ""
echo "Web UI will be available at: http://localhost:7860"
echo "API will be available at: http://localhost:5000"
echo ""

# Navigate to the correct directory
cd /app/text-generation-webui

# Use the official launcher
bash start_linux.sh \
    --model "Qwen2.5-7B-Instruct-Q4_K_M.gguf" \
    --api \
    --listen \
    --listen-host 0.0.0.0 \
    --listen-port 7860 \
    --api-port 5000 \
    --loader llama.cpp \
    --n-gpu-layers 35 \
    --threads 4