#!/bin/bash
# SDN Load Balancer - Start Mininet Only

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║    SDN Dynamic Load Balancer - Mininet Network Terminal     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 DEMO TERMINAL 2/3 - MININET NETWORK EMULATOR"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 STEP 1: Initializing Open vSwitch (OVS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   → Checking OVS service status..."
echo ""

# Check OVS
if ! sudo systemctl is-active --quiet openvswitch-switch; then
    echo "   → Starting Open vSwitch service..."
    sudo systemctl start openvswitch-switch
    sleep 2
    echo "   ✅ Open vSwitch started"
else
    echo "   ✅ Open vSwitch already running"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 STEP 2: Cleaning Previous Network Sessions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   → Removing stale network configurations..."
echo ""

# Clean up any previous Mininet sessions
sudo mn -c >/dev/null 2>&1 || true
sleep 1

echo "   ✅ Previous sessions cleaned"
echo ""

# Wait for controller to be ready
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 STEP 3: Verifying Controller Connection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   ⚠️  IMPORTANT: Ensure RYU Controller is running!"
echo "   → Check Terminal 1 for controller status"
echo "   → Controller should be listening on port 6653"
echo ""
echo "   ⏳ Waiting 3 seconds for controller verification..."
sleep 3
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 STEP 4: Creating Virtual Network Topology"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   🌐 Network Topology:"
echo "      • Topology Type: Single Switch with 4 Hosts"
echo "      • Switch: s1 (OpenFlow-enabled)"
echo "      • Hosts: h1, h2, h3, h4"
echo "      • Controller: Remote @ 127.0.0.1:6653"
echo ""
echo "   🔄 Load Balancing Setup:"
echo "      • Virtual IP: 10.0.0.1 (Load Balancer)"
echo "      • Backend Servers: h2, h3, h4"
echo "      • Client: h1"
echo ""
echo "   📝 Available Test Commands (use in Mininet CLI):"
echo "      ┌────────────────────────────────────────────────────────┐"
echo "      │ h1 ping -c 10 10.0.0.1  → Test load balancing         │"
echo "      │ pingall                  → Test connectivity           │"
echo "      │ net                      → Display network topology    │"
echo "      │ nodes                    → List all nodes              │"
echo "      │ links                    → Show all links              │"
echo "      │ dump                     → Display detailed node info  │"
echo "      │ h1 ifconfig              → Check h1 IP configuration   │"
echo "      │ xterm h1 h2              → Open terminal windows       │"
echo "      └────────────────────────────────────────────────────────┘"
echo ""
echo "   💡 For Demo: Watch Terminal 1 (Controller logs) while testing!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Starting Mininet... (Type 'exit' or Ctrl+D to quit)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
sleep 2

# Start Mininet with verbose output
sudo mn --topo single,4 --mac --controller remote,ip=127.0.0.1,port=6653 --switch ovsk -v info

# Cleanup after Mininet exits
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 Cleaning up network resources..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo mn -c >/dev/null 2>&1 || true
echo "✅ Mininet stopped and cleaned up"
echo ""
