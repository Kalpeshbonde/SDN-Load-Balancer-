#!/usr/bin/env python3
"""
Dynamic Load Balancer using RYU SDN Controller
Supports: Round-Robin and Dynamic (CPU-based) Load Balancing
"""

import logging
import json
from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import CONFIG_DISPATCHER, MAIN_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.ofproto import ofproto_v1_3
from ryu.lib.packet import packet, ethernet, ether_types, ipv4, tcp, udp, icmp
from ryu.lib import hub
import time

# Configure logging level (DEBUG for development, INFO for demo)
LOG_LEVEL = logging.INFO  # Change to logging.DEBUG for detailed logs
logging.basicConfig(level=LOG_LEVEL)


class LoadBalancerController(app_manager.RyuApp):
    """
    SDN Load Balancer Controller
    - Intercepts traffic to virtual IP (10.0.0.1)
    - Distributes load across backend servers
    - Supports round-robin and dynamic algorithms
    """
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super(LoadBalancerController, self).__init__(*args, **kwargs)
        
        # Network Configuration
        self.VIRTUAL_IP = "10.0.0.1"
        self.SERVER_IPS = ["10.0.0.2", "10.0.0.3", "10.0.0.4"]  # h2, h3, h4
        self.SERVER_MACS = ["00:00:00:00:00:02", "00:00:00:00:00:03", "00:00:00:00:00:04"]
        
        # Load Balancing State
        self.algorithm = "round-robin"  # Options: "round-robin", "dynamic"
        self.next_server = 0
        self.server_loads = {ip: 0 for ip in self.SERVER_IPS}
        self.active_connections = {}
        
        # Statistics
        self.stats = {
            "total_requests": 0,
            "server_hits": {ip: 0 for ip in self.SERVER_IPS},
            "start_time": time.time()
        }
        
        # Flow table for connection tracking
        self.flow_table = {}
        
        self.logger.info("=" * 60)
        self.logger.info("SDN Dynamic Load Balancer Started")
        self.logger.info(f"Virtual IP: {self.VIRTUAL_IP}")
        self.logger.info(f"Backend Servers: {self.SERVER_IPS}")
        self.logger.info(f"Algorithm: {self.algorithm}")
        self.logger.info("=" * 60)
        
        # Start monitoring thread (for dynamic mode)
        self.monitor_thread = hub.spawn(self._monitor)

    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def switch_features_handler(self, ev):
        """
        Handle switch connection - install default flow rules
        """
        datapath = ev.msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        # Install table-miss flow entry (send to controller)
        match = parser.OFPMatch()
        actions = [parser.OFPActionOutput(ofproto.OFPP_CONTROLLER,
                                          ofproto.OFPCML_NO_BUFFER)]
        self.add_flow(datapath, 0, match, actions)
        
        self.logger.info(f"Switch connected: {datapath.id}")

    def add_flow(self, datapath, priority, match, actions, idle_timeout=30, hard_timeout=0):
        """
        Add flow rule to OpenFlow switch
        idle_timeout: Flow expires after 30s of inactivity
        """
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        inst = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS, actions)]
        mod = parser.OFPFlowMod(datapath=datapath, priority=priority,
                                match=match, instructions=inst,
                                idle_timeout=idle_timeout,
                                hard_timeout=hard_timeout)
        datapath.send_msg(mod)

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def packet_in_handler(self, ev):
        """
        Handle incoming packets - main load balancing logic
        """
        msg = ev.msg
        datapath = msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        in_port = msg.match['in_port']

        # Parse packet
        pkt = packet.Packet(msg.data)
        eth = pkt.get_protocol(ethernet.ethernet)
        
        if eth.ethertype == ether_types.ETH_TYPE_LLDP:
            return  # Ignore LLDP packets

        # Extract IP layer
        ip_pkt = pkt.get_protocol(ipv4.ipv4)
        if not ip_pkt:
            return  # Not an IP packet

        src_ip = ip_pkt.src
        dst_ip = ip_pkt.dst

        self.logger.debug(f"Packet: {src_ip} -> {dst_ip} (port {in_port})")

        # Check if destination is our virtual IP
        if dst_ip == self.VIRTUAL_IP:
            # Traffic to virtual IP - apply load balancing
            self._handle_lb_request(datapath, pkt, in_port, src_ip, eth.src)
        elif dst_ip in self.SERVER_IPS:
            # Return traffic from server to client
            self._handle_lb_response(datapath, pkt, in_port, dst_ip)
        else:
            # Regular forwarding
            self._simple_forward(datapath, pkt, in_port)

    def _handle_lb_request(self, datapath, pkt, in_port, client_ip, client_mac):
        """
        Handle load balancing for client -> virtual IP traffic
        """
        parser = datapath.ofproto_parser
        ofproto = datapath.ofproto

        # Select backend server
        server_ip, server_mac = self._select_server(client_ip)
        
        self.stats["total_requests"] += 1
        self.stats["server_hits"][server_ip] += 1
        self.server_loads[server_ip] += 1

        self.logger.info(f"[LB] Client {client_ip} -> Server {server_ip} "
                        f"(Total: {self.stats['total_requests']})")

        # Store connection mapping
        self.active_connections[client_ip] = server_ip

        # Install flow: client -> server (rewrite dst IP and MAC)
        match = parser.OFPMatch(
            in_port=in_port,
            eth_type=ether_types.ETH_TYPE_IP,
            ipv4_src=client_ip,
            ipv4_dst=self.VIRTUAL_IP
        )
        
        server_port = self._get_server_port(server_ip)
        actions = [
            parser.OFPActionSetField(eth_dst=server_mac),
            parser.OFPActionSetField(ipv4_dst=server_ip),
            parser.OFPActionOutput(server_port)
        ]
        
        self.add_flow(datapath, 10, match, actions, idle_timeout=30)

        # Install reverse flow: server -> client (rewrite src IP and MAC)
        match_reverse = parser.OFPMatch(
            in_port=server_port,
            eth_type=ether_types.ETH_TYPE_IP,
            ipv4_src=server_ip,
            ipv4_dst=client_ip
        )
        
        actions_reverse = [
            parser.OFPActionSetField(eth_src="00:00:00:00:00:01"),  # Virtual MAC
            parser.OFPActionSetField(ipv4_src=self.VIRTUAL_IP),
            parser.OFPActionOutput(in_port)
        ]
        
        self.add_flow(datapath, 10, match_reverse, actions_reverse, idle_timeout=30)

        # Forward the current packet
        out = parser.OFPPacketOut(
            datapath=datapath,
            buffer_id=ofproto.OFP_NO_BUFFER,
            in_port=in_port,
            actions=actions,
            data=pkt.data
        )
        datapath.send_msg(out)

    def _handle_lb_response(self, datapath, pkt, in_port, dst_ip):
        """
        Handle server -> client response traffic
        """
        # This is handled by reverse flow rules
        # Just forward if no rule exists
        self._simple_forward(datapath, pkt, in_port)

    def _simple_forward(self, datapath, pkt, in_port):
        """
        Simple L2 forwarding for non-load-balanced traffic
        """
        parser = datapath.ofproto_parser
        ofproto = datapath.ofproto
        
        eth = pkt.get_protocol(ethernet.ethernet)
        dst_mac = eth.dst
        
        # Flood packet on all ports
        actions = [parser.OFPActionOutput(ofproto.OFPP_FLOOD)]
        out = parser.OFPPacketOut(
            datapath=datapath,
            buffer_id=ofproto.OFP_NO_BUFFER,
            in_port=in_port,
            actions=actions,
            data=pkt.data
        )
        datapath.send_msg(out)

    def _select_server(self, client_ip):
        """
        Select backend server using configured algorithm
        """
        if self.algorithm == "round-robin":
            return self._select_round_robin()
        elif self.algorithm == "dynamic":
            return self._select_dynamic()
        else:
            return self._select_round_robin()

    def _select_round_robin(self):
        """
        Round-robin selection (baseline algorithm)
        """
        server_ip = self.SERVER_IPS[self.next_server]
        server_mac = self.SERVER_MACS[self.next_server]
        
        self.next_server = (self.next_server + 1) % len(self.SERVER_IPS)
        
        return server_ip, server_mac

    def _select_dynamic(self):
        """
        Dynamic selection based on current load
        Select server with minimum active connections
        """
        min_load = min(self.server_loads.values())
        for i, ip in enumerate(self.SERVER_IPS):
            if self.server_loads[ip] == min_load:
                return ip, self.SERVER_MACS[i]
        
        # Fallback to round-robin
        return self._select_round_robin()

    def _get_server_port(self, server_ip):
        """
        Map server IP to switch port
        h2 (10.0.0.2) -> port 2
        h3 (10.0.0.3) -> port 3
        h4 (10.0.0.4) -> port 4
        """
        port_map = {
            "10.0.0.2": 2,
            "10.0.0.3": 3,
            "10.0.0.4": 4
        }
        return port_map.get(server_ip, 2)

    def _monitor(self):
        """
        Background monitoring thread
        Periodically decay server loads and print stats
        """
        while True:
            hub.sleep(10)
            
            # Decay server loads (simulate connection termination)
            for ip in self.server_loads:
                self.server_loads[ip] = max(0, self.server_loads[ip] - 1)
            
            # Print statistics
            if self.stats["total_requests"] > 0:
                self.logger.info("=" * 60)
                self.logger.info(f"STATS: Total Requests = {self.stats['total_requests']}")
                for ip in self.SERVER_IPS:
                    hits = self.stats["server_hits"][ip]
                    load = self.server_loads[ip]
                    self.logger.info(f"  {ip}: {hits} hits, current load: {load}")
                self.logger.info("=" * 60)

    def set_algorithm(self, algorithm):
        """
        Switch load balancing algorithm
        """
        if algorithm in ["round-robin", "dynamic"]:
            self.algorithm = algorithm
            self.logger.info(f"Algorithm changed to: {algorithm}")
        else:
            self.logger.warning(f"Unknown algorithm: {algorithm}")
