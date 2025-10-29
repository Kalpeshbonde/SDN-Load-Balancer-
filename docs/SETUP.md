# Environment Setup Guide

Complete installation and configuration guide for the SDN Dynamic Load Balancer.

---

## 🖥️ System Requirements

### Operating System
- **Linux** (Ubuntu 20.04+ or Arch Linux recommended)
- Root/sudo access required

### Hardware Requirements
- **CPU**: 2+ cores
- **RAM**: 4GB minimum (8GB recommended)
- **Disk**: 5GB free space

---

## 📦 Installation

### ⚠️ ARCH LINUX USERS - READ THIS FIRST

**Critical:** Arch Linux ships Python 3.13, which is **incompatible** with RYU Framework.

**Recommended Solution: Use Docker**
```bash
cd /path/to/dynamic-load-balancer
./install_docker.sh    # Build Docker image with Ubuntu + Python 3.10
./run_docker.sh        # Run the container
```

**Alternative Solutions:**
- Use Conda with Python 3.11
- Build Python 3.11 from source
- Use pyenv

For all installation methods, see: **[INSTALL_OPTIONS.md](../INSTALL_OPTIONS.md)**

---

### Step 1: Update System

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt upgrade -y
```

**Arch Linux:**
```bash
sudo pacman -Syu
```

---

### Step 2: Install Python

**Ubuntu/Debian:**
```bash
sudo apt install python3 python3-pip python3-venv -y
```

**Arch Linux:**
```bash
# Install Python 3.11 (NOT the default python package which is 3.13)
yay -S python311  # or: paru -S python311

# Also install pip
sudo pacman -S python-pip
```

Verify installation:
```bash
# Ubuntu
python3 --version  # Should show 3.8-3.12

# Arch
python3.11 --version  # Should show 3.11.x
```

---

### Step 3: Install Mininet

Mininet is the network emulator that simulates our SDN topology.

**Ubuntu/Debian:**
```bash
sudo apt install mininet -y
```

**Arch Linux:**
```bash
# Install from AUR
yay -S mininet
# OR build from source
git clone https://github.com/mininet/mininet
cd mininet
sudo ./util/install.sh -a
```

Verify installation:
```bash
sudo mn --version
```

---

### Step 4: Install Open vSwitch

Open vSwitch is the OpenFlow-compatible switch.

**Ubuntu/Debian:**
```bash
sudo apt install openvswitch-switch -y
sudo systemctl start openvswitch-switch
sudo systemctl enable openvswitch-switch
```

**Arch Linux:**
```bash
sudo pacman -S openvswitch
sudo systemctl enable ovs-vswitchd ovsdb-server
sudo systemctl start ovsdb-server
sudo systemctl start ovs-vswitchd
```

**Verify Open vSwitch is running:**
```bash
sudo systemctl status ovs-vswitchd
sudo ovs-vsctl show
```

---

### Step 5: Set Up Python Virtual Environment

**Ubuntu/Debian:**
```bash
cd /path/to/dynamic-load-balancer
python3 -m venv venv
source venv/bin/activate
```

**Arch Linux:**
```bash
cd /path/to/dynamic-load-balancer
# Use Python 3.11 specifically
python3.11 -m venv venv
source venv/bin/activate
```

---

### Step 6: Install Python Dependencies

```bash
pip install --upgrade pip setuptools wheel

# Install packages individually (more reliable than requirements.txt)
pip install ryu==4.34
pip install Flask Flask-CORS psutil eventlet
```

This installs:
- **RYU Framework 4.34** (SDN controller)
- **Flask** (Dashboard web framework)
- **psutil** (System monitoring)
- **eventlet** (Async networking)
- Other dependencies

---

## ✅ Verification

### Test 1: RYU Installation
```bash
ryu-manager --version
```
Expected output: `ryu-manager 4.34` (or similar)

### Test 2: Mininet Installation
```bash
sudo mn --test pingall
```
Expected output: Successful ping between all hosts

### Test 3: Python Dependencies
```bash
python3 -c "import ryu; import flask; import psutil; print('All dependencies installed!')"
```

---

## 🔧 Optional Tools

### Wireshark (For Packet Analysis)
**Ubuntu/Debian:**
```bash
sudo apt install wireshark -y
```

**Arch Linux:**
```bash
sudo pacman -S wireshark-qt
```

### tcpdump (For Traffic Capture)
```bash
sudo apt install tcpdump  # Ubuntu
sudo pacman -S tcpdump     # Arch
```

---

## 🐛 Troubleshooting

### Issue: "Permission denied" when running Mininet
**Solution:** Mininet requires root privileges
```bash
sudo ./run_mininet.sh
```

### Issue: "Cannot connect to controller"
**Solution:** Ensure RYU controller is running before Mininet
```bash
# Terminal 1
./run_controller.sh

# Terminal 2 (wait 5 seconds)
sudo ./run_mininet.sh
```

### Issue: "Module 'ryu' not found"
**Solution:** Activate virtual environment
```bash
source venv/bin/activate
pip install -r requirements.txt
```

### Issue: Mininet cleanup needed
**Solution:** Clean previous instances
```bash
sudo mn -c
```

---

## 🚀 Next Steps

Once setup is complete, proceed to [USAGE.md](USAGE.md) for execution instructions.
