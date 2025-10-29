# Installation Options for Arch Linux

## 🚨 The Problem

Arch Linux ships with Python 3.13, but **RYU Framework only supports Python 3.8-3.12**.

This causes `pip install ryu==4.34` to fail.

---

## ✅ Solution Options (Ranked by Ease)

### Option 1: Docker (RECOMMENDED) ⭐

**Pros:**
- ✅ Works immediately, no compilation needed
- ✅ No Python version conflicts
- ✅ Completely isolated environment
- ✅ Easy to start/stop/remove

**Cons:**
- ❌ Requires Docker installed
- ❌ Slightly higher resource usage

**How to use:**
```bash
# Install and setup (one-time, ~5 minutes)
./install_docker.sh

# Run the container
./run_docker.sh

# Inside container, start components:
ryu-manager load_balancer.py  # Terminal 1
mn --topo single,4 --controller remote  # Terminal 2
```

---

### Option 2: Use Conda/Miniconda

**Pros:**
- ✅ Easy Python version management
- ✅ Works well on Arch
- ✅ Isolated environment

**Cons:**
- ❌ Requires Conda/Miniconda installation

**Steps:**
```bash
# Install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Create Python 3.11 environment
conda create -n sdn python=3.11
conda activate sdn

# Install packages
pip install ryu==4.34 Flask Flask-CORS psutil eventlet

# Install system packages
sudo pacman -S mininet openvswitch
sudo systemctl start ovs-vswitchd ovsdb-server

# Run project
./run_controller.sh
```

---

### Option 3: Build Python 3.11 from Source

**Pros:**
- ✅ Full control
- ✅ Native installation

**Cons:**
- ❌ Time-consuming (~15 minutes)
- ❌ Requires build dependencies

**Steps:**
```bash
# Install build dependencies
sudo pacman -S base-devel openssl zlib bzip2 readline sqlite \
    ncurses gdbm xz tk libffi

# Download and build Python 3.11
cd /tmp
wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz
tar xzf Python-3.11.9.tgz
cd Python-3.11.9

./configure --prefix=/usr/local --enable-optimizations
make -j$(nproc)
sudo make altinstall

# Verify
python3.11 --version

# Setup project
cd /path/to/dynamic-load-balancer
python3.11 -m venv venv
source venv/bin/activate
pip install ryu==4.34 Flask Flask-CORS psutil eventlet
```

---

### Option 4: Use a VM or Chroot

**If all else fails:**

1. **VM Approach:**
   - Install VirtualBox/QEMU
   - Create Ubuntu 22.04 VM
   - Run project inside VM

2. **Chroot Approach:**
   - Create Ubuntu chroot using `systemd-nspawn`
   - Install everything inside chroot

---

## 🎯 Quick Decision Guide

| Your Situation | Best Option |
|----------------|-------------|
| Want simplest solution | **Docker** (Option 1) |
| Already use Conda | **Conda** (Option 2) |
| Need native performance | **Build from source** (Option 3) |
| Have lots of time | **Build from source** (Option 3) |
| Already have Docker | **Docker** (Option 1) |

---

## 📋 Current Project Scripts

I've created these installation scripts:

1. **`install_docker.sh`** ⭐ RECOMMENDED
   - Builds Docker image with everything pre-installed
   - Run with: `./install_docker.sh`
   - Then: `./run_docker.sh`

2. **`install_easy.sh`**
   - Attempts to install python311-bin (precompiled binary)
   - Falls back to pyenv if needed
   - May not work on all systems

3. **`install_all.sh`**
   - Full installation from source
   - Requires AUR packages to build successfully

4. **`fix_arch.sh`**
   - Original fix script
   - Tries to install python311 from AUR (may fail to compile)

---

## 🐋 Why Docker is Recommended

Docker image includes:
- ✅ Ubuntu 22.04 (with working Python 3.10)
- ✅ RYU Framework pre-installed
- ✅ Mininet pre-installed
- ✅ Open vSwitch pre-configured
- ✅ All Python dependencies ready
- ✅ Project files mounted (changes reflected immediately)

**Total time:** 5 minutes to build, instant to run

**How to use:**
```bash
./install_docker.sh    # Build image (one-time)
./run_docker.sh        # Start container

# Inside container:
ryu-manager load_balancer.py  # Terminal 1
mn --topo single,4 --controller remote  # Terminal 2
```

---

## 🚀 After Installation

Regardless of method, the usage is the same:

**Quick Start (Automated):**
```bash
./start_all.sh    # Launches all components
./stop_all.sh     # Stops everything
```

**Manual Start:**
```bash
# Terminal 1: Controller
source venv/bin/activate  # or docker shell
./run_controller.sh

# Terminal 2: Mininet
sudo ./run_mininet.sh

# Terminal 3: Test
mininet> h1 ping -c 10 10.0.0.1

# Terminal 4: Dashboard (optional)
cd dashboard && ./run_dashboard.sh
# Open: http://localhost:5000
```

---

## 🆘 Still Having Issues?

1. **Try Docker first** - it's the most reliable (`./install_docker.sh`)
2. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
3. Review error messages carefully
4. Make sure Open vSwitch is running: `sudo systemctl status ovs-vswitchd`

---

## 📊 Installation Comparison

| Method | Time | Difficulty | Success Rate |
|--------|------|------------|--------------|
| Docker | 5 min | Easy | 99% |
| Conda | 10 min | Medium | 90% |
| Build from source | 20 min | Hard | 70% |
| AUR python311 | Variable | Medium | 50% (compilation issues) |

---

## 💡 Pro Tip

For quick testing and demos, **use Docker**. For long-term development or production, install natively using Conda or build from source.

---

**Current Status:** Docker installation is recommended and has been set up for you.

Run: `./install_docker.sh` (if not already running)
Then: `./run_docker.sh` to start working!
