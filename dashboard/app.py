#!/usr/bin/env python3
"""
Flask Dashboard for SDN Load Balancer
Real-time monitoring and statistics visualization
"""

from flask import Flask, render_template, jsonify
from flask_cors import CORS
import json
import time
import random

app = Flask(__name__)
CORS(app)

# Simulated statistics (in production, this would connect to RYU controller)
stats = {
    "total_requests": 0,
    "active_connections": 0,
    "servers": [
        {"ip": "10.0.0.2", "name": "Server 1", "hits": 0, "load": 0, "status": "active"},
        {"ip": "10.0.0.3", "name": "Server 2", "hits": 0, "load": 0, "status": "active"},
        {"ip": "10.0.0.4", "name": "Server 3", "hits": 0, "load": 0, "status": "active"}
    ],
    "algorithm": "round-robin",
    "start_time": time.time()
}


@app.route('/')
def index():
    """
    Main dashboard page
    """
    return render_template('index.html')


@app.route('/api/stats')
def get_stats():
    """
    API endpoint for real-time statistics
    Returns current load balancer stats as JSON
    """
    # Simulate some activity (in production, read from RYU controller)
    stats["total_requests"] += random.randint(0, 3)
    stats["active_connections"] = random.randint(5, 20)
    
    for server in stats["servers"]:
        server["hits"] += random.randint(0, 2)
        server["load"] = random.randint(0, 100)
    
    # Calculate uptime
    uptime_seconds = int(time.time() - stats["start_time"])
    uptime_hours = uptime_seconds // 3600
    uptime_minutes = (uptime_seconds % 3600) // 60
    uptime_str = f"{uptime_hours}h {uptime_minutes}m"
    
    return jsonify({
        "total_requests": stats["total_requests"],
        "active_connections": stats["active_connections"],
        "servers": stats["servers"],
        "algorithm": stats["algorithm"],
        "uptime": uptime_str,
        "timestamp": time.time()
    })


@app.route('/api/algorithm/<algo>')
def set_algorithm(algo):
    """
    API endpoint to change load balancing algorithm
    """
    if algo in ["round-robin", "dynamic"]:
        stats["algorithm"] = algo
        return jsonify({"success": True, "algorithm": algo})
    return jsonify({"success": False, "error": "Invalid algorithm"}), 400


@app.route('/api/reset')
def reset_stats():
    """
    Reset statistics
    """
    stats["total_requests"] = 0
    stats["active_connections"] = 0
    for server in stats["servers"]:
        server["hits"] = 0
        server["load"] = 0
    stats["start_time"] = time.time()
    
    return jsonify({"success": True})


if __name__ == '__main__':
    print("=" * 60)
    print("SDN Load Balancer Dashboard")
    print("=" * 60)
    print("Dashboard URL: http://localhost:5000")
    print("Press Ctrl+C to stop")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5000, debug=True)
