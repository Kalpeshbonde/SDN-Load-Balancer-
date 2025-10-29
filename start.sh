#!/bin/bash
# SDN Load Balancer - Start Everything

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      SDN Dynamic Load Balancer - Starting                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Detect environment
if [ -f /etc/debian_version ]; then
    ENV="ubuntu-native"
else
    ENV="unknown"
fi

# (Docker and Arch Linux helper paths removed)
# The script now assumes a native environment (e.g., Ubuntu) or will show
# an error if the environment can't be detected.

# ============================================================================
# UBUNTU (Native)
# ============================================================================
if [ "$ENV" = "ubuntu-native" ]; then
    echo "Ubuntu detected - running natively..."
    echo ""
    
    # Check if venv exists
    if [ ! -d "venv" ]; then
        echo "❌ Virtual environment not found. Run ./install.sh first"
        exit 1
    fi
    
    # Activate venv
    source venv/bin/activate
    
    # Check OVS
    if ! sudo systemctl is-active --quiet openvswitch-switch; then
        echo "Starting Open vSwitch..."
        sudo systemctl start openvswitch-switch
        sleep 2
    fi
    
    # Clean up
    sudo mn -c >/dev/null 2>&1 || true
    
    # Start controller in background
    echo "1. Starting RYU Controller..."
    nohup ryu-manager load_balancer.py > controller.log 2>&1 &
    CONTROLLER_PID=$!
    echo "   ✅ Started (PID: $CONTROLLER_PID, logs: controller.log)"
    sleep 3
    
    # Start dashboard in background
    echo "2. Starting Dashboard..."
    cd dashboard
    nohup python3 app.py > dashboard.log 2>&1 &
    DASHBOARD_PID=$!
    cd ..
    echo "   ✅ Started (PID: $DASHBOARD_PID, logs: dashboard/dashboard.log)"
    echo "   🌐 http://localhost:5000"
    
    # Start Mininet (interactive)
    echo ""
    echo "3. Starting Mininet (requires sudo)..."
    echo "   Type 'exit' or Ctrl+D to quit"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test: h1 ping -c 10 10.0.0.1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    sleep 2
    
    sudo mn --topo single,4 --mac --controller remote --switch ovsk
    
    # Cleanup after Mininet exits
    echo ""
    echo "Cleaning up..."
    kill $CONTROLLER_PID $DASHBOARD_PID 2>/dev/null || true
    sudo mn -c >/dev/null 2>&1 || true
    echo "✅ Stopped"

else
    echo "❌ Unable to detect environment"
    echo "Run ./install.sh first"
    exit 1
fi