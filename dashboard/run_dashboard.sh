#!/bin/bash
# Launch Flask Dashboard for SDN Load Balancer

echo "========================================="
echo "Starting Flask Dashboard"
echo "========================================="
echo ""
echo "Dashboard URL: http://localhost:5000"
echo "Press Ctrl+C to stop"
echo ""

# Activate virtual environment if it exists
if [ -d "../venv" ]; then
    source ../venv/bin/activate
fi

# Run Flask app
python3 app.py
