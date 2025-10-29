#!/bin/bash
# SDN Load Balancer - Start RYU Controller Only

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      SDN Dynamic Load Balancer - Starting Controller        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if venv exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Run ./install.sh first"
    exit 1
fi

# Activate venv
source venv/bin/activate

# Start RYU Controller
echo "Starting RYU Controller..."
echo "Logs will be written to: controller.log"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Controller will listen on port 6653"
echo "Press Ctrl+C to stop"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Start controller (foreground so you can see logs and stop with Ctrl+C)
ryu-manager load_balancer.py
