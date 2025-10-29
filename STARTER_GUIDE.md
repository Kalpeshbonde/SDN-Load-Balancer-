# SDN Dynamic Load Balancer - Quick Start Guide

## 🚀 Prerequisites

- **Ubuntu/Debian Linux** (native or WSL2 on Windows)
- **Python 3.8+**
- **Root/sudo access** (required for Mininet)

## 📦 Installation

```bash
# Clone the repository (if not already done)
git clone https://github.com/tejbruhath/dynamic-load-balancer.git
cd dynamic-load-balancer

# Run the installation script
./install.sh
```

The installer will:
- Create a Python virtual environment
- Install RYU SDN controller
- Install Mininet
- Install Flask and dependencies
- Set up Open vSwitch

## 🎯 Running the Load Balancer

You have **two options** to run the system:

### Option 1: All-in-One (Single Terminal)

Run everything together with automatic startup:

```bash
./start.sh
```

This will:
1. Start the RYU Controller in the background
2. Start the Dashboard in the background
3. Launch Mininet in interactive mode

When you're done, just type `exit` in Mininet. Everything will be cleaned up automatically.

---

### Option 2: Separate Terminals (Recommended for Development)

Run each component in its own terminal for better visibility and control.

#### Terminal 1 - RYU Controller
```bash
cd dynamic-load-balancer
./start_controller.sh
```
- You'll see real-time controller logs
- Press `Ctrl+C` to stop

#### Terminal 2 - Mininet Network
```bash
cd dynamic-load-balancer
./start_mininet.sh
```
- Interactive Mininet CLI
- Type `exit` or `Ctrl+D` to quit

#### Terminal 3 - Dashboard (Optional)
```bash
cd dynamic-load-balancer/dashboard
source ../venv/bin/activate
python3 app.py
```
- Visit http://localhost:5000 in your browser
- Press `Ctrl+C` to stop

---

## 🧪 Testing the Load Balancer

Once Mininet is running, try these commands in the Mininet CLI:

### Test Load Balancing
```bash
mininet> h1 ping -c 10 10.0.0.1
```
This sends 10 pings through the load balancer. Watch the controller logs to see load distribution!

### Test All Hosts
```bash
mininet> pingall
```

### Get Host Info
```bash
mininet> net
mininet> nodes
mininet> links
```

### Run Commands on Hosts
```bash
mininet> h1 ifconfig
mininet> h2 ip addr
```

### Traffic Generation
```bash
mininet> h1 iperf -s &
mininet> h2 iperf -c 10.0.0.1 -t 30
```

---

## 📊 Monitoring Dashboard

The web dashboard (http://localhost:5000) shows:
- Real-time server loads
- Traffic distribution
- Active connections
- Load balancing algorithm status

Refresh the page to see updated metrics.

---

## 🛑 Stopping the System

### If using All-in-One mode:
Just type `exit` in Mininet - everything stops automatically.

Or use:
```bash
./stop.sh
```

### If using Separate Terminals:
Press `Ctrl+C` in each terminal, or run:
```bash
./stop.sh
```

This will:
- Clean up Mininet
- Stop the RYU Controller
- Stop the Dashboard
- Remove log files

---

## 📁 Project Structure

```
dynamic-load-balancer/
├── start.sh              # All-in-one startup script
├── start_controller.sh   # Start RYU Controller only
├── start_mininet.sh      # Start Mininet only
├── stop.sh               # Stop all components
├── install.sh            # Installation script
├── load_balancer.py      # RYU Controller application
├── requirements.txt      # Python dependencies
└── dashboard/
    ├── app.py           # Flask dashboard
    └── templates/
        └── index.html   # Dashboard UI
```

---

## 📝 Log Files

- `controller.log` - RYU Controller logs
- `dashboard/dashboard.log` - Dashboard logs
- `nohup.out` - Background process output

---

## 🔧 Troubleshooting

### "Virtual environment not found"
```bash
./install.sh
```

### "Open vSwitch not running"
```bash
sudo systemctl start openvswitch-switch
sudo systemctl status openvswitch-switch
```

### "Cannot connect to controller"
Make sure the controller is running and listening on port 6653:
```bash
netstat -tlnp | grep 6653
```

### Clean up stuck Mininet processes
```bash
sudo mn -c
sudo pkill -f mininet
```

### Permission errors
Make sure you have sudo access:
```bash
sudo -v
```

---

## 🌟 Next Steps

1. **Modify the topology** - Edit `start_mininet.sh` to change `--topo single,4` to other topologies
2. **Customize load balancing** - Edit `load_balancer.py` to implement different algorithms
3. **Enhance the dashboard** - Modify `dashboard/app.py` and templates

---

## 📚 Additional Resources

- [RYU SDN Framework Documentation](https://ryu.readthedocs.io/)
- [Mininet Documentation](http://mininet.org/)
- [Open vSwitch Documentation](https://www.openvswitch.org/)

---

## 💡 Quick Command Reference

| Task | Command |
|------|---------|
| Install | `./install.sh` |
| Start All | `./start.sh` |
| Start Controller Only | `./start_controller.sh` |
| Start Mininet Only | `./start_mininet.sh` |
| Stop All | `./stop.sh` |
| Clean Mininet | `sudo mn -c` |
| View Controller Logs | `tail -f controller.log` |
| View Dashboard | http://localhost:5000 |

---

**Happy Load Balancing! 🎉**
