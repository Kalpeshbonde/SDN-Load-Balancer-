# Usage Guide

Step-by-step instructions for running and testing the SDN Dynamic Load Balancer.

---

## 🚀 Quick Start (3 Steps)

### Step 1: Start RYU Controller

Open **Terminal 1**:
```bash
cd /path/to/dynamic-load-balancer
source venv/bin/activate  # Activate virtual environment
./run_controller.sh
```

Expected output:
```
=========================================
Starting RYU SDN Load Balancer Controller
=========================================
loading app load_balancer.py
instantiating app load_balancer.py of LoadBalancerController
============================================================
SDN Dynamic Load Balancer Started
Virtual IP: 10.0.0.1
Backend Servers: ['10.0.0.2', '10.0.0.3', '10.0.0.4']
Algorithm: round-robin
============================================================
```

**Keep this terminal running!**

---

### Step 2: Start Mininet Topology

Open **Terminal 2**:
```bash
cd /path/to/dynamic-load-balancer
sudo ./run_mininet.sh
```

Expected output:
```
=========================================
Starting Mininet Network Topology
=========================================

Topology:
  h1 (10.0.0.1) - Client
  h2 (10.0.0.2) - Backend Server 1
  h3 (10.0.0.3) - Backend Server 2
  h4 (10.0.0.4) - Backend Server 3
  s1           - OpenFlow Switch

mininet>
```

You should now see the `mininet>` prompt.

---

### Step 3: Test Load Balancing

In the Mininet CLI (`mininet>` prompt):

#### Test 1: Basic Connectivity
```bash
mininet> pingall
```
All hosts should be able to ping each other.

#### Test 2: Load Balancer Test
```bash
mininet> h1 ping -c 10 10.0.0.1
```

**What to observe:**
- Look at **Terminal 1** (RYU controller logs)
- You should see requests being distributed across servers:
  ```
  [LB] Client 10.0.0.1 -> Server 10.0.0.2 (Total: 1)
  [LB] Client 10.0.0.1 -> Server 10.0.0.3 (Total: 2)
  [LB] Client 10.0.0.1 -> Server 10.0.0.4 (Total: 3)
  [LB] Client 10.0.0.1 -> Server 10.0.0.2 (Total: 4)
  ```

This confirms **round-robin load balancing** is working!

---

## 🎯 Automated Testing

For automated traffic tests, use the provided test script:

Open **Terminal 3**:
```bash
cd /path/to/dynamic-load-balancer
sudo ./traffic_test.sh
```

This script:
1. Launches Mininet automatically
2. Sends 15 ICMP requests to the virtual IP
3. Logs server rotation
4. Shows pass/fail for each request

---

## 📊 Dashboard (Optional)

To visualize traffic in real-time:

Open **Terminal 4**:
```bash
cd /path/to/dynamic-load-balancer/dashboard
source ../venv/bin/activate
./run_dashboard.sh
```

Open browser and navigate to:
```
http://localhost:5000
```

The dashboard shows:
- ✅ Total requests
- ✅ Active connections
- ✅ Server utilization
- ✅ Traffic distribution chart

---

## 🧪 Advanced Testing

### Test 1: Continuous Traffic
Generate continuous traffic to see load distribution:

```bash
mininet> h1 ping 10.0.0.1
# Press Ctrl+C after 30 seconds
```

Check **Terminal 1** for statistics every 10 seconds.

### Test 2: Multiple Clients
Open multiple client connections:

```bash
mininet> xterm h1
# In the new xterm window:
ping 10.0.0.1
```

### Test 3: HTTP Traffic (Advanced)
Start a web server on each backend:

```bash
mininet> h2 python3 -m http.server 80 &
mininet> h3 python3 -m http.server 80 &
mininet> h4 python3 -m http.server 80 &

# Test with curl
mininet> h1 curl http://10.0.0.1
```

---

## ⚙️ Configuration

### Change Load Balancing Algorithm

Edit `load_balancer.py` line 39:
```python
self.algorithm = "dynamic"  # Options: "round-robin", "dynamic"
```

Then restart the controller.

### Adjust Flow Timeout

Edit `load_balancer.py` line 88:
```python
self.add_flow(datapath, priority, match, actions, idle_timeout=60)  # 60 seconds
```

### Change Logging Level

Edit `load_balancer.py` line 19:
```python
LOG_LEVEL = logging.DEBUG  # DEBUG for detailed logs, INFO for clean output
```

---

## 🛑 Stopping the System

### Stop Mininet
In the Mininet terminal:
```bash
mininet> exit
```

### Stop RYU Controller
In Terminal 1:
```bash
Press Ctrl+C
```

### Cleanup Mininet
Always clean up after stopping:
```bash
sudo mn -c
```

### Stop Dashboard
In Terminal 4:
```bash
Press Ctrl+C
```

---

## 📸 Demo Screenshots

For your project report/demo, capture:

1. **Controller logs** showing round-robin distribution
   ```bash
   # In Terminal 1, take screenshot of controller output
   ```

2. **Mininet ping results**
   ```bash
   mininet> h1 ping -c 20 10.0.0.1
   # Screenshot showing successful pings
   ```

3. **Dashboard visualization**
   ```bash
   # Screenshot of http://localhost:5000
   ```

4. **Statistics output**
   ```bash
   # Screenshot of STATS output in controller logs
   ```

---

## 🔍 Debugging Tips

### View OpenFlow Rules
```bash
sudo ovs-ofctl dump-flows s1
```

### View Switch Configuration
```bash
sudo ovs-vsctl show
```

### Monitor Traffic with tcpdump
```bash
sudo tcpdump -i s1-eth1 -n
```

---

## 📚 Next Steps

- Read [ARCHITECTURE.md](ARCHITECTURE.md) for technical details
- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
