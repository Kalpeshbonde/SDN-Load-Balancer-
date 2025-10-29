#!/bin/bash
# SDN Load Balancer - Stop Everything

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      Stopping SDN Dynamic Load Balancer                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Stop Mininet (requires sudo)
echo "1. Cleaning up Mininet..."
sudo mn -c >/dev/null 2>&1 || true
echo "   ✅ Done"

# Stop RYU Controller
echo "2. Stopping RYU Controller..."
pkill -f "ryu-manager" >/dev/null 2>&1 || true
echo "   ✅ Done"

# Stop Dashboard
echo "3. Stopping Dashboard..."
pkill -f "dashboard/app.py" >/dev/null 2>&1 || true
pkill -f "app.py" >/dev/null 2>&1 || true
echo "   ✅ Done"

# Cleanup logs
echo "4. Cleaning up logs..."
rm -f controller.log dashboard/dashboard.log nohup.out
echo "   ✅ Done"

echo ""
echo "✅ All components stopped!"
echo ""
echo "To start again: ./start.sh"
echo ""