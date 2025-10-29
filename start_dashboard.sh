#!/bin/bash
# SDN Load Balancer - Start Dashboard Only

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║    SDN Dynamic Load Balancer - Dashboard Terminal           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 DEMO TERMINAL 3/3 - WEB DASHBOARD (OPTIONAL)"
echo ""

# Check if venv exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Run ./install.sh first"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 STEP 1: Activating Python Environment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   → Loading Flask web framework..."
echo ""

source venv/bin/activate
sleep 1

echo "   ✅ Environment activated"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 STEP 2: Starting Web Dashboard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   📊 Dashboard Features:"
echo "      • Real-time server load monitoring"
echo "      • Traffic distribution visualization"
echo "      • Active connection tracking"
echo "      • Load balancing algorithm status"
echo "      • Network topology view"
echo ""
echo "   🌐 Access Dashboard:"
echo "      • URL: http://localhost:5000"
echo "      • URL: http://127.0.0.1:5000"
echo ""
echo "   💡 For Demo: Open this URL in your browser!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Press Ctrl+C to stop the dashboard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
sleep 2

cd dashboard
python3 app.py
