#!/bin/bash
# Quick fix for stuck Mininet

echo "Cleaning up stuck processes..."
pkill -f ryu-manager
pkill -f app.py
pkill -f mininet
mn -c 2>/dev/null

echo "✅ Cleaned up!"
echo ""
echo "Now run: ./start.sh"
