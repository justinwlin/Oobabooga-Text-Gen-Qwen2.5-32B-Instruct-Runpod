FROM justinrunpod/pod-server-base:1.0

ENV DEBIAN_FRONTEND=noninteractive
ENV MODEL_NAME="bartowski/Qwen2.5-32B-Instruct-GGUF"
ENV MODEL_FILE="Qwen2.5-32B-Instruct-Q4_K_M.gguf"

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    wget \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN rm -rf /app/*
RUN mkdir -p /app

WORKDIR /app

RUN git clone https://github.com/oobabooga/text-generation-webui.git

WORKDIR /app/text-generation-webui

# Create models directory
RUN mkdir -p user_data/models

# Set environment variables for the official installer
ENV GPU_CHOICE="A"
ENV LAUNCH_AFTER_INSTALL="false"

# Run the official installer
RUN echo "A" | bash start_linux.sh --install-deps || true

# Download model using oobabooga's official download script
RUN echo "=== Downloading model using official download-model.py ===" && \
    python download-model.py $MODEL_NAME && \
    echo "=== Download completed ==="

# Check where the model was downloaded and move GGUF file to root models directory
RUN echo "=== Checking download results ===" && \
    ls -la user_data/models/ && \
    echo "=== Looking for GGUF files ===" && \
    find user_data/models/ -name "*.gguf" && \
    echo "=== Moving GGUF file to root models directory ===" && \
    find user_data/models/ -name "$MODEL_FILE" -exec mv {} user_data/models/ \; && \
    echo "=== Cleaning up download directory ===" && \
    rm -rf user_data/models/bartowski_* && \
    echo "=== Final models directory ===" && \
    ls -la user_data/models/

# Verify model file exists (FAIL BUILD IF MISSING)
RUN echo "=== Verifying model download ===" && \
    [ -f "user_data/models/$MODEL_FILE" ] && echo "✅ Model file exists: $MODEL_FILE" || (echo "❌ Model file missing: $MODEL_FILE" && exit 1)

# Copy startup scripts
COPY start_server.sh check_status.sh ./
RUN chmod +x start_server.sh check_status.sh

# Unset the launch variable so manual startup works
ENV LAUNCH_AFTER_INSTALL=""

EXPOSE 7860 5000

# Final verification
RUN echo "=== FINAL VERIFICATION ===" && \
    [ -f "user_data/models/$MODEL_FILE" ] && echo "✅ Model ready: $MODEL_FILE" || (echo "❌ Model missing" && exit 1) && \
    [ -d "installer_files" ] && echo "✅ Installer files exist" || (echo "❌ No installer files" && exit 1) && \
    echo "✅ Container ready for use!"

# Copy handler.py for serverless mode
COPY handler.py /app/handler.py

# Copy requirements.txt and install Python dependencies
COPY requirements.txt /app/requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Copy our custom start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Explicitly set the CMD to call our start script
CMD ["/start.sh"]