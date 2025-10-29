#!/bin/bash
# SDN Load Balancer - Complete Installation
# Works for both Arch Linux (Docker) and Ubuntu (native)

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      SDN Dynamic Load Balancer - Installation               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Detect OS
if [ -f /etc/arch-release ]; then
    OS="arch"
    echo "✓ Detected: Arch Linux"
    echo "✓ Will use Docker (Python 3.13 incompatibility)"
elif [ -f /etc/debian_version ]; then
    OS="ubuntu"
    echo "✓ Detected: Ubuntu/Debian"
    echo "✓ Will install natively"
else
    echo "❌ Unsupported OS"
    exit 1
fi

echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# ============================================================================
# ARCH LINUX - DOCKER INSTALLATION
# ============================================================================
if [ "$OS" = "arch" ]; then
    echo ""
    echo "Installing Docker-based environment..."
    
    # Install Docker if needed
    if ! command -v docker >/dev/null 2>&1; then
        echo "Installing Docker..."
        sudo pacman -S --noconfirm docker
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        echo "⚠️  Log out and back in for docker group to take effect"
    fi
    
    # Build Docker image
    echo "Building Docker image (takes ~5 minutes)..."
    cat > Dockerfile << 'EOF'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    python3 python3-pip mininet openvswitch-switch \
    net-tools iputils-ping iproute2 \
    && rm -rf /var/lib/apt/lists/*
RUN pip3 install --no-cache-dir ryu==4.34 Flask Flask-CORS psutil eventlet
WORKDIR /app
COPY . /app/
RUN chmod +x *.sh 2>/dev/null || true
CMD ["/bin/bash"]
EOF
    
    sudo docker build -t sdn-lb .
    
    echo ""
    echo "✅ Docker installation complete!"
    echo ""
    echo "To run: ./start.sh"
    
# ============================================================================
# UBUNTU - NATIVE INSTALLATION
# ============================================================================
else
    echo ""
    echo "Installing native environment..."
    
    # Install system packages
    echo "Installing system packages..."
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv mininet openvswitch-switch
    
    # Create virtual environment
    echo "Setting up Python environment..."
    python3 -m venv venv
    source venv/bin/activate
    
    # Install Python packages
    echo "Installing Python packages..."
    pip install --upgrade pip
    pip install ryu==4.34 Flask Flask-CORS psutil eventlet
    
    # Start Open vSwitch
    echo "Starting Open vSwitch..."
    sudo systemctl enable openvswitch-switch
    sudo systemctl start openvswitch-switch
    
    echo ""
    echo "✅ Native installation complete!"
    echo ""
    echo "To run: ./start.sh"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installation Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "OS: $OS"
if [ "$OS" = "arch" ]; then
    echo "Method: Docker"
else
    echo "Method: Native"
fi
echo ""
echo "Next steps:"
echo "  1. ./start.sh    # Start the system"
echo "  2. ./stop.sh     # Stop the system"
echo ""
