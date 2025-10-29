# System Architecture

Technical design and implementation details of the SDN Dynamic Load Balancer.

---

## 🏗️ System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     RYU SDN Controller                      │
│              (load_balancer.py - Python)                    │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  • Packet Processing                                  │  │
│  │  • Flow Rule Installation                             │  │
│  │  • Load Balancing Logic (Round-Robin / Dynamic)       │  │
│  │  • Connection Tracking                                │  │
│  └───────────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │ OpenFlow Protocol
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              OpenFlow Switch (Open vSwitch)                 │
│                        Switch s1                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Flow Table (idle_timeout=30s)                      │   │
│  │  • Match: src_ip, dst_ip, in_port                   │   │
│  │  • Action: modify IP/MAC, forward to port           │   │
│  └─────────────────────────────────────────────────────┘   │
└──┬──────────┬──────────┬──────────┬────────────────────────┘
   │          │          │          │
   │ Port 1   │ Port 2   │ Port 3   │ Port 4
   ↓          ↓          ↓          ↓
┌─────┐   ┌─────┐   ┌─────┐   ┌─────┐
│ h1  │   │ h2  │   │ h3  │   │ h4  │
│ Client   │Server│Server│Server│
│10.0.0.1│ │10.0.0.2│10.0.0.3│10.0.0.4│
└─────┘   └─────┘   └─────┘   └─────┘
```

---

## 🧩 Component Breakdown

### 1. RYU SDN Controller (`load_balancer.py`)

**Role:** Central brain of the network
- Receives packets from OpenFlow switch
- Decides routing and load distribution
- Installs flow rules dynamically
- Tracks connections and statistics

**Key Classes:**
- `LoadBalancerController` - Main application class (inherits from `RyuApp`)

**Key Methods:**
- `switch_features_handler()` - Initialize switch connection
- `packet_in_handler()` - Process incoming packets
- `_handle_lb_request()` - Load balance client→VIP traffic
- `_select_server()` - Choose backend server
- `add_flow()` - Install OpenFlow rules

---

### 2. Mininet Network Emulator

**Role:** Simulates the network topology
- Creates virtual hosts (h1-h4)
- Creates OpenFlow switch (s1)
- Connects to remote RYU controller

**Topology:**
```
Hosts: 4
Switch: 1 (OpenFlow 1.3)
Links: 4 (host-to-switch)
Controller: Remote (127.0.0.1:6653)
```

---

### 3. OpenFlow Switch (Open vSwitch)

**Role:** Programmable data plane
- Receives flow rules from controller
- Forwards packets based on installed rules
- Sends unknown packets to controller

**Flow Table Structure:**
```
Priority | Match Fields              | Actions                    | Timeout
---------|---------------------------|----------------------------|--------
10       | src=10.0.0.1, dst=VIP    | set_dst_ip, forward        | 30s
10       | src=server, dst=client   | set_src_ip, forward        | 30s
0        | any                       | send to controller         | permanent
```

---

## 🔄 Traffic Flow

### Request Flow (Client → Virtual IP → Server)

```
1. h1 sends ping to 10.0.0.1 (Virtual IP)
   ↓
2. Packet arrives at switch s1
   ↓
3. No matching flow → send to controller (PACKET_IN)
   ↓
4. Controller receives packet
   ↓
5. Controller selects server (e.g., 10.0.0.2) using algorithm
   ↓
6. Controller installs TWO flow rules:
   
   Rule 1 (Forward path):
   Match: src=10.0.0.1, dst=10.0.0.1
   Action: set_dst_ip=10.0.0.2, set_dst_mac=00:00:00:00:00:02, forward to port 2
   
   Rule 2 (Reverse path):
   Match: src=10.0.0.2, dst=10.0.0.1
   Action: set_src_ip=10.0.0.1, set_src_mac=00:00:00:00:00:01, forward to port 1
   ↓
7. Controller forwards current packet to server
   ↓
8. h2 receives packet (appears to come from 10.0.0.1)
   ↓
9. h2 sends reply
   ↓
10. Switch matches reverse flow rule → forwards to h1
   ↓
11. h1 receives reply (appears to come from 10.0.0.1)
```

### Subsequent Requests
- **Within 30 seconds:** Switch handles directly (no controller)
- **After 30 seconds:** Flow expires → new selection round

---

## ⚙️ Load Balancing Algorithms

### 1. Round-Robin (Baseline)

**Logic:**
```python
server_index = (current_index + 1) % num_servers
```

**Characteristics:**
- ✅ Simple and predictable
- ✅ Equal distribution (statistically)
- ❌ Ignores server load
- ❌ May overload slow servers

**Use Case:** Homogeneous servers with similar capacity

---

### 2. Dynamic (CPU-Based)

**Logic:**
```python
server = min(servers, key=lambda s: s.current_load)
```

**Characteristics:**
- ✅ Load-aware routing
- ✅ Adapts to server capacity
- ✅ Better for heterogeneous servers
- ❌ Requires monitoring overhead

**Use Case:** Servers with different capacities or variable workloads

**Note:** Current implementation uses connection count as proxy for load. Can be extended with `psutil` for actual CPU monitoring.

---

## 🔐 Connection Tracking

### Flow State Management

**Problem:** How to ensure all packets from the same connection go to the same server?

**Solution:** Bidirectional flow rules
- **Forward rule:** Client → VIP becomes Client → Server
- **Reverse rule:** Server → Client becomes VIP → Client

**Timeout Strategy:**
- `idle_timeout=30s` - Flow expires after 30s of inactivity
- New connections may be routed to different servers
- Long-lived connections stay on the same server

---

## 📊 Statistics & Monitoring

### Tracked Metrics
1. **Total Requests** - Cumulative count
2. **Server Hits** - Per-server request count
3. **Active Connections** - Current connection count
4. **Server Load** - Current load per server

### Monitoring Thread
- Runs every 10 seconds
- Decays server load counters
- Prints statistics to console
- Can be extended to export metrics

---

## 🔌 OpenFlow Protocol

### Messages Used

| Message Type    | Direction            | Purpose                          |
|-----------------|----------------------|----------------------------------|
| PACKET_IN       | Switch → Controller  | Unknown packet for processing    |
| PACKET_OUT      | Controller → Switch  | Forward specific packet          |
| FLOW_MOD        | Controller → Switch  | Install/modify flow rule         |
| FEATURES_REQ    | Controller → Switch  | Query switch capabilities        |
| FEATURES_REPLY  | Switch → Controller  | Report switch features           |

### OpenFlow Version
- **Version:** OpenFlow 1.3
- **Reason:** Better multi-table support, more flexible matching

---

## 🧪 Extensibility

### Adding New Algorithms

1. Implement selection method:
```python
def _select_least_latency(self):
    # Your logic here
    return server_ip, server_mac
```

2. Update `_select_server()`:
```python
elif self.algorithm == "least-latency":
    return self._select_least_latency()
```

### Adding Health Checks

```python
def _monitor(self):
    while True:
        hub.sleep(5)
        for server_ip in self.SERVER_IPS:
            # Send ICMP ping
            alive = self._ping_server(server_ip)
            if not alive:
                self._mark_server_down(server_ip)
```

### Integrating with Dashboard

Expose REST API in controller:
```python
@app.route('/api/stats')
def get_stats():
    return jsonify(self.stats)
```

---

## 🎓 Key Design Decisions

### 1. Virtual IP Approach
**Why?** Allows transparent load balancing without DNS changes

### 2. Flow-Based (vs Packet-Based)
**Why?** Better performance - switch handles packets directly after first one

### 3. Short Flow Timeouts (30s)
**Why?** Balance between performance and load redistribution

### 4. Stateless Server Selection
**Why?** Simpler implementation, easier to debug

---

## 📚 References

- **RYU Documentation:** https://ryu.readthedocs.io/
- **OpenFlow 1.3 Spec:** https://www.opennetworking.org/
- **Mininet Documentation:** http://mininet.org/
- **Open vSwitch:** https://www.openvswitch.org/
