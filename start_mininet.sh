#!/bin/bash
# SDN Load Balancer - Start Mininet Only

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      SDN Dynamic Load Balancer - Starting Mininet           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check OVS
if ! sudo systemctl is-active --quiet openvswitch-switch; then
    echo "Starting Open vSwitch..."
    sudo systemctl start openvswitch-switch
    sleep 2
fi

# Clean up any previous Mininet sessions
echo "Cleaning up previous Mininet sessions..."
sudo mn -c >/dev/null 2>&1 || true

# Wait for controller to be ready
echo ""
echo "⏳ Make sure the RYU Controller is running first!"
echo "   (Run ./start_controller.sh in another terminal)"
echo ""
echo "Waiting 3 seconds..."
sleep 3

# Start Mininet (interactive)
echo ""
echo "Starting Mininet (interactive)..."
echo "Type 'exit' or Ctrl+D to quit"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test commands:"
echo "  h1 ping -c 10 10.0.0.1    # Test load balancing"
echo "  pingall                   # Test all hosts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Start Mininet with verbose output
sudo mn --topo single,4 --mac --controller remote,ip=127.0.0.1,port=6653 --switch ovsk -v info

# Cleanup after Mininet exits
echo ""
echo "Cleaning up..."
sudo mn -c >/dev/null 2>&1 || true
echo "✅ Mininet stopped"
