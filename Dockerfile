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
