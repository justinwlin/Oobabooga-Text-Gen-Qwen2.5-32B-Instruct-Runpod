#!/bin/bash
echo "Starting text-generation-webui server with official launcher..."
echo ""
echo "Web UI will be available at: http://localhost:7860"
echo "API will be available at: http://localhost:5000"
echo "Using model: $MODEL_FILE"
echo ""

# Navigate to the correct directory
cd /app/text-generation-webui

# Reset environment variables that prevent launching
unset LAUNCH_AFTER_INSTALL
export GPU_CHOICE="A"

# Use the official launcher with environment variable
bash start_linux.sh \
    --model "$MODEL_FILE" \
    --api \
    --listen \
    --listen-host 0.0.0.0 \
    --listen-port 7860 \
    --api-port 5000 \
    --loader llama.cpp \
    --n-gpu-layers 35 \
    --threads 4