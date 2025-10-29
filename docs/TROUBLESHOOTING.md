# Troubleshooting Guide

Common issues and solutions for the SDN Dynamic Load Balancer.

---

## 🔴 Installation Issues

### Issue 1: "Command 'ryu-manager' not found"

**Cause:** RYU not installed or not in PATH

**Solutions:**

1. **Check if virtual environment is activated:**
```bash
source venv/bin/activate
```

2. **Check if RYU is installed:**
```bash
pip list | grep ryu
```

3. **Reinstall RYU:**
```bash
pip install --upgrade ryu==4.34
```

4. **On Arch Linux:** Use Docker to avoid Python 3.13 issues:
```bash
./install_docker.sh
./run_docker.sh
```

---

### Issue 2: "Cannot import name 'soft_unicode' from 'markupsafe'"

**Cause:** Incompatible MarkupSafe version with Flask

**Solution:**
```bash
pip install markupsafe==2.0.1
pip install --upgrade flask
```

---

### Issue 3: Mininet installation fails on Arch Linux

**Cause:** Mininet not available in official repos

**Solutions:**

**Option 1:** Install from AUR
```bash
yay -S mininet
# or
paru -S mininet
```

**Option 2:** Build from source
```bash
git clone https://github.com/mininet/mininet
cd mininet
git checkout 2.3.0
sudo ./util/install.sh -a
```

---

## 🔴 Runtime Issues

### Issue 4: "Cannot connect to controller" in Mininet

**Cause:** Controller not running or wrong IP/port

**Diagnosis:**
```bash
# Check if controller is listening
sudo netstat -tlnp | grep 6653
# Should show: tcp 0.0.0.0:6653 LISTEN ryu-manager
```

**Solutions:**

1. **Start controller FIRST**, then Mininet:
```bash
# Terminal 1
./run_controller.sh
# Wait 5 seconds

# Terminal 2
sudo ./run_mininet.sh
```

2. Check controller logs for errors

3. Verify controller IP in Mininet:
```bash
sudo mn --controller remote,ip=127.0.0.1,port=6653
```

---

### Issue 5: "No route to host" when pinging virtual IP

**Cause:** Flow rules not installed correctly

**Diagnosis:**
```bash
# Check installed flows
sudo ovs-ofctl dump-flows s1

# Should show multiple flows with actions like:
# set_field:10.0.0.2->ip_dst, output:2
```

**Solutions:**

1. Enable DEBUG logging in `load_balancer.py`:
```python
LOG_LEVEL = logging.DEBUG
```

2. Restart controller and check logs for PACKET_IN events

3. Verify switch connection:
```bash
# In controller logs, look for:
# "Switch connected: 1"
```

4. Clear flows and retry:
```bash
sudo ovs-ofctl del-flows s1
# Then ping again from Mininet
```

---

### Issue 6: Packets timeout / No response

**Cause:** Various - flow rules, routing, firewall

**Diagnosis Steps:**

1. **Test basic connectivity** (bypass load balancer):
```bash
mininet> h1 ping h2
# Should work
```

2. **Check if packets reach switch:**
```bash
sudo tcpdump -i s1-eth1 -n icmp
# Should see ICMP packets
```

3. **Check controller logs:**
```bash
# Look for "Packet: 10.0.0.1 -> 10.0.0.1"
# And "[LB] Client 10.0.0.1 -> Server 10.0.0.X"
```

4. **Verify flow installation:**
```bash
sudo ovs-ofctl dump-flows s1 | grep 10.0.0.1
```

**Solutions:**

1. If step 1 fails:
```bash
sudo mn -c
sudo ./run_mininet.sh
```

2. If step 3 shows no logs:
   - Controller not receiving packets
   - Check OpenFlow connection:
```bash
sudo ovs-vsctl show
# Look for "is_connected: true"
```

3. If step 4 shows no flows:
   - Flow installation failing
   - Check controller error logs

---

### Issue 7: "Address already in use" (Flask dashboard)

**Cause:** Port 5000 already occupied

**Solutions:**

1. **Kill existing process:**
```bash
sudo lsof -ti:5000 | xargs kill -9
```

2. **Change port** in `dashboard/app.py`:
```python
app.run(host='0.0.0.0', port=8080, debug=True)
```

---

### Issue 8: Mininet CLI unresponsive / frozen

**Cause:** Previous Mininet instance not cleaned up

**Solution:**
```bash
# Exit Mininet (Ctrl+D or 'exit')
sudo mn -c

# If still stuck, kill processes:
sudo killall -9 controller ovs-testcontroller ovs-controller
sudo killall -9 ovsdb-server ovs-vswitchd
sudo service openvswitch-switch restart  # Ubuntu
sudo systemctl restart ovs-vswitchd      # Arch

# Then restart
sudo ./run_mininet.sh
```

---

## 🔴 Performance Issues

### Issue 9: High latency / slow response

**Cause:** Controller processing overhead

**Solutions:**

1. **Reduce logging:**
```python
LOG_LEVEL = logging.INFO  # or WARNING
```

2. **Increase flow timeout** (reduce controller load):
```python
self.add_flow(datapath, priority, match, actions, idle_timeout=60)
```

3. **Use proactive flows** (install rules at startup instead of reactive)

---

### Issue 10: Uneven load distribution

**Cause:** Flow caching - same client keeps hitting same server

**Diagnosis:**
```bash
# Check flow table
sudo ovs-ofctl dump-flows s1

# Look for idle_time - if low, flow is being reused
```

**Solutions:**

1. **Reduce idle timeout:**
```python
idle_timeout=10  # More frequent redistribution
```

2. **Use different clients:**
```bash
mininet> h2 ping 10.0.0.1
mininet> h3 ping 10.0.0.1
```

3. **Clear flows between tests:**
```bash
sudo ovs-ofctl del-flows s1
```

---

## 🔴 Dashboard Issues

### Issue 11: Dashboard shows all zeros

**Cause:** Dashboard not connected to controller

**Current Status:** Dashboard uses simulated data

**Solution (Future Enhancement):**
Implement REST API in controller:
```python
# In load_balancer.py
from flask import Flask
api = Flask(__name__)

@api.route('/api/stats')
def get_stats():
    return jsonify(self.stats)

# Run in separate thread
```

---

### Issue 12: Dashboard CSS/JS not loading

**Cause:** CDN blocked or offline

**Solution:**
Check browser console (F12) for errors. If CDN blocked:

1. Download libraries locally:
```bash
cd dashboard/static
wget https://cdn.tailwindcss.com/tailwind.css
wget https://cdn.jsdelivr.net/npm/chart.js/dist/chart.min.js
```

2. Update `index.html` to use local files

---

## 🔴 Network Issues

### Issue 13: "Cannot resolve hostname" errors

**Cause:** DNS not configured in Mininet

**Solution:**
```bash
mininet> h1 echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

---

### Issue 14: "Operation not permitted" with Open vSwitch

**Cause:** Not running with sufficient privileges

**Solution:**
```bash
# Always use sudo with Mininet and ovs commands
sudo ./run_mininet.sh
sudo ovs-ofctl dump-flows s1
```

---

## 🔴 Code Issues

### Issue 15: "AttributeError: 'LoadBalancerController' has no attribute 'X'"

**Cause:** Missing initialization in `__init__`

**Solution:**
Check that all attributes are initialized in `__init__()`:
```python
def __init__(self, *args, **kwargs):
    super(LoadBalancerController, self).__init__(*args, **kwargs)
    self.VIRTUAL_IP = "10.0.0.1"
    self.SERVER_IPS = [...]
    # etc.
```

---

## 🛠️ General Debugging Tips

### Enable Full Debug Logging

**Controller:**
```python
LOG_LEVEL = logging.DEBUG
```

**Mininet:**
```bash
sudo mn --controller remote --verbosity debug
```

**Open vSwitch:**
```bash
sudo ovs-appctl vlog/set dbg
```

---

### Packet Capture

Capture traffic on specific interface:
```bash
# Capture switch-to-host traffic
sudo tcpdump -i s1-eth2 -w capture.pcap

# Open in Wireshark
wireshark capture.pcap
```

Filter for OpenFlow packets:
```bash
sudo tcpdump -i lo port 6653 -X
```

---

### Check System Resources

```bash
# CPU usage
top

# Memory usage
free -h

# Disk usage
df -h

# Network interfaces
ip addr show
```

---

## 📞 Getting Help

### Before Asking for Help

1. ✅ Check logs (controller + mininet)
2. ✅ Run `sudo mn -c` to clean up
3. ✅ Verify all components are installed
4. ✅ Test basic connectivity first
5. ✅ Check this troubleshooting guide

### What to Include

When reporting issues, provide:
- Operating system and version
- Error messages (full output)
- Controller logs
- Output of `sudo ovs-ofctl dump-flows s1`
- Steps to reproduce

---

## 🔄 Full System Reset

If all else fails:

```bash
# 1. Stop everything
sudo mn -c
killall ryu-manager
killall python3

# 2. Restart Open vSwitch
sudo systemctl restart openvswitch-switch  # Ubuntu
sudo systemctl restart ovs-vswitchd       # Arch

# 3. Clear virtual environment
deactivate
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. Start fresh
./run_controller.sh  # Terminal 1
sudo ./run_mininet.sh  # Terminal 2
```

---

## 📚 Additional Resources

- **RYU Troubleshooting:** https://ryu.readthedocs.io/en/latest/troubleshooting.html
- **Mininet FAQ:** http://mininet.org/faq/
- **Open vSwitch FAQ:** https://docs.openvswitch.org/en/latest/faq/
