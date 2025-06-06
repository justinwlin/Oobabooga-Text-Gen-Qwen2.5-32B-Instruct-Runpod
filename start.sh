#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value
# ---------------------------------------------------------------------------- #
#                          Function Definitions                                #
# ---------------------------------------------------------------------------- #
# Start nginx service
start_nginx() {
    echo "Starting Nginx service..."
    service nginx start
}
# Execute script if exists
execute_script() {
    local script_path=$1
    local script_msg=$2
    if [[ -f ${script_path} ]]; then
        echo "${script_msg}"
        bash ${script_path}
    fi
}
# Setup ssh
setup_ssh() {
    if [[ $PUBLIC_KEY ]]; then
        echo "Setting up SSH..."
        mkdir -p ~/.ssh
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
        chmod 700 -R ~/.ssh
        # Generate SSH host keys if not present
        generate_ssh_keys
        service ssh start
        echo "SSH host keys:"
        cat /etc/ssh/*.pub
    fi
}
# Generate SSH host keys
generate_ssh_keys() {
    ssh-keygen -A
}
# Export env vars
export_env_vars() {
    echo "Exporting environment variables..."
    printenv | grep -E '^RUNPOD_|^PATH=|^_=' | awk -F = '{ print "export " $1 "=\"" $2 "\"" }' >> /etc/rp_environment
    echo 'source /etc/rp_environment' >> ~/.bashrc
}
# Start jupyter lab
start_jupyter() {
    echo "Starting Jupyter Lab..."
    mkdir -p /workspace && \
    cd / && \
    nohup jupyter lab --allow-root --no-browser --port=8888 --ip=* --NotebookApp.token='' --NotebookApp.password='' --FileContentsManager.delete_to_trash=False --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' --ServerApp.allow_origin=* --ServerApp.preferred_dir=/workspace &> /jupyter.log &
    echo "Jupyter Lab started without a password"
}

# Start text-generation-webui
start_textgen() {
    echo "Starting text-generation-webui server..."
    cd /app/text-generation-webui && nohup ./start_server.sh > /var/log/textgen.log 2>&1 &
    echo "Text-generation-webui started in background"
    
    # Wait for the API to be ready
    echo "Waiting for text-generation-webui API to be ready..."
    local max_attempts=60  # Maximum wait time in seconds
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f http://localhost:5000/v1/models > /dev/null 2>&1; then
            echo "✓ Text-generation-webui API is ready!"
            break
        else
            echo "Waiting for API... (attempt $((attempt + 1))/$max_attempts)"
            sleep 1
            attempt=$((attempt + 1))
        fi
    done
    
    if [ $attempt -eq $max_attempts ]; then
        echo "⚠️  Warning: API did not respond within $max_attempts seconds"
        echo "Check logs: tail -f /var/log/textgen.log"
        return 1
    fi
    
    echo "Web UI: http://localhost:7860"
    echo "API: http://localhost:5000"
    echo "Logs: tail -f /var/log/textgen.log"
}

# Call Python handler if mode is serverless or both
call_python_handler() {
    echo "Calling Python handler.py..."
    python /app/handler.py
}
# ---------------------------------------------------------------------------- #
#                               Main Program                                   #
# ---------------------------------------------------------------------------- #
start_nginx
echo "Pod Started"
setup_ssh
start_textgen

# Check MODE_TO_RUN and call functions accordingly
case $MODE_TO_RUN in
    serverless)
        call_python_handler
        ;;
    pod)
        # Pod mode implies starting services without calling handler.py
        start_jupyter
        ;;
    *)
        echo "Invalid MODE_TO_RUN value: $MODE_TO_RUN. Expected 'serverless' or 'pod'."
        exit 1
        ;;
esac
export_env_vars
echo "Start script(s) finished, pod is ready to use."
sleep infinity