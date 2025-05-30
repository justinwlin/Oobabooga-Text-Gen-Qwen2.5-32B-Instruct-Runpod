#!/bin/bash
echo "Checking server status..."
curl -s http://localhost:7860 >/dev/null && echo "✅ Web UI: Running" || echo "❌ Web UI: Not running"
curl -s http://localhost:5000/v1/models >/dev/null && echo "✅ API: Running" || echo "❌ API: Not running"
pgrep -f "server.py" > /dev/null && echo "✅ Process: Running (PID: $(pgrep -f server.py))" || echo "❌ Process: Not running"