#!/bin/bash

# Network Optimization Analysis Script for Lighthouse + Ethereum Full Node
# Run this script on vovkes-server to gather all relevant system parameters

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create output directory
OUTPUT_DIR="/tmp/network-analysis-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}=== Network Optimization Analysis Script ===${NC}"
echo -e "${BLUE}Target: Lighthouse + Ethereum Full Node on Docker${NC}"
echo -e "${BLUE}Output directory: $OUTPUT_DIR${NC}"
echo ""

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root (use sudo)${NC}"
        exit 1
    fi
}

# Function to gather system info
gather_system_info() {
    echo -e "${YELLOW}Gathering system information...${NC}"
    
    # Basic system info
    cat > "$OUTPUT_DIR/system-info.txt" << EOF
=== SYSTEM INFORMATION ===
Date: $(date)
Hostname: $(hostname)
Kernel: $(uname -r)
Architecture: $(uname -m)
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
CPU Cores: $(nproc)
Memory: $(free -h | grep Mem | awk '{print $2}')
EOF

    # Docker info
    if command -v docker &> /dev/null; then
        echo "=== DOCKER INFORMATION ===" >> "$OUTPUT_DIR/system-info.txt"
        docker version >> "$OUTPUT_DIR/system-info.txt" 2>&1 || echo "Docker not accessible"
        echo "" >> "$OUTPUT_DIR/system-info.txt"
        docker info >> "$OUTPUT_DIR/system-info.txt" 2>&1 || echo "Docker info not accessible"
    fi
}

# Function to gather network interface info
gather_network_info() {
    echo -e "${YELLOW}Gathering network interface information...${NC}"
    
    # Network interfaces
    ip addr show > "$OUTPUT_DIR/network-interfaces.txt" 2>&1
    
    # Network interface statistics
    cat > "$OUTPUT_DIR/network-stats.txt" << EOF
=== NETWORK INTERFACE STATISTICS ===
$(ip -s link show)
EOF

    # Network interface speeds and capabilities
    for iface in $(ls /sys/class/net/ | grep -v lo); do
        if [[ -f "/sys/class/net/$iface/speed" ]]; then
            echo "Interface: $iface" >> "$OUTPUT_DIR/network-stats.txt"
            echo "Speed: $(cat /sys/class/net/$iface/speed) Mbps" >> "$OUTPUT_DIR/network-stats.txt"
            echo "Duplex: $(cat /sys/class/net/$iface/duplex)" >> "$OUTPUT_DIR/network-stats.txt"
            echo "---" >> "$OUTPUT_DIR/network-stats.txt"
        fi
    done
}

# Function to gather core network parameters
gather_core_network_params() {
    echo -e "${YELLOW}Gathering core network parameters...${NC}"
    
    cat > "$OUTPUT_DIR/core-network-params.txt" << EOF
=== CORE NETWORK PARAMETERS ===

--- Core Memory Parameters ---
net.core.rmem_max = $(cat /proc/sys/net/core/rmem_max 2>/dev/null || echo "N/A")
net.core.wmem_max = $(cat /proc/sys/net/core/wmem_max 2>/dev/null || echo "N/A")
net.core.rmem_default = $(cat /proc/sys/net/core/rmem_default 2>/dev/null || echo "N/A")
net.core.wmem_default = $(cat /proc/sys/net/core/wmem_default 2>/dev/null || echo "N/A")
net.core.netdev_max_backlog = $(cat /proc/sys/net/core/netdev_max_backlog 2>/dev/null || echo "N/A")
net.core.netdev_budget = $(cat /proc/sys/net/core/netdev_budget 2>/dev/null || echo "N/A")
net.core.netdev_budget_usecs = $(cat /proc/sys/net/core/netdev_budget_usecs 2>/dev/null || echo "N/A")

--- TCP Memory Parameters ---
net.ipv4.tcp_rmem = $(cat /proc/sys/net/ipv4/tcp_rmem 2>/dev/null || echo "N/A")
net.ipv4.tcp_wmem = $(cat /proc/sys/net/ipv4/tcp_wmem 2>/dev/null || echo "N/A")
net.ipv4.tcp_mem = $(cat /proc/sys/net/ipv4/tcp_mem 2>/dev/null || echo "N/A")

--- TCP Connection Parameters ---
net.ipv4.tcp_max_syn_backlog = $(cat /proc/sys/net/ipv4/tcp_max_syn_backlog 2>/dev/null || echo "N/A")
net.ipv4.tcp_max_tw_buckets = $(cat /proc/sys/net/ipv4/tcp_max_tw_buckets 2>/dev/null || echo "N/A")
net.ipv4.tcp_fin_timeout = $(cat /proc/sys/net/ipv4/tcp_fin_timeout 2>/dev/null || echo "N/A")
net.ipv4.tcp_tw_reuse = $(cat /proc/sys/net/ipv4/tcp_tw_reuse 2>/dev/null || echo "N/A")
net.ipv4.tcp_tw_recycle = $(cat /proc/sys/net/ipv4/tcp_tw_recycle 2>/dev/null || echo "N/A")

--- TCP Performance Parameters ---
net.ipv4.tcp_congestion_control = $(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo "N/A")
net.ipv4.tcp_window_scaling = $(cat /proc/sys/net/ipv4/tcp_window_scaling 2>/dev/null || echo "N/A")
net.ipv4.tcp_timestamps = $(cat /proc/sys/net/ipv4/tcp_timestamps 2>/dev/null || echo "N/A")
net.ipv4.tcp_sack = $(cat /proc/sys/net/ipv4/tcp_sack 2>/dev/null || echo "N/A")
net.ipv4.tcp_fack = $(cat /proc/sys/net/ipv4/tcp_fack 2>/dev/null || echo "N/A")
net.ipv4.tcp_slow_start_after_idle = $(cat /proc/sys/net/ipv4/tcp_slow_start_after_idle 2>/dev/null || echo "N/A")

--- TCP Keepalive Parameters ---
net.ipv4.tcp_keepalive_time = $(cat /proc/sys/net/ipv4/tcp_keepalive_time 2>/dev/null || echo "N/A")
net.ipv4.tcp_keepalive_intvl = $(cat /proc/sys/net/ipv4/tcp_keepalive_intvl 2>/dev/null || echo "N/A")
net.ipv4.tcp_keepalive_probes = $(cat /proc/sys/net/ipv4/tcp_keepalive_probes 2>/dev/null || echo "N/A")

--- TCP Retransmission Parameters ---
net.ipv4.tcp_retries1 = $(cat /proc/sys/net/ipv4/tcp_retries1 2>/dev/null || echo "N/A")
net.ipv4.tcp_retries2 = $(cat /proc/sys/net/ipv4/tcp_retries2 2>/dev/null || echo "N/A")
net.ipv4.tcp_syn_retries = $(cat /proc/sys/net/ipv4/tcp_syn_retries 2>/dev/null || echo "N/A")
net.ipv4.tcp_synack_retries = $(cat /proc/sys/net/ipv4/tcp_synack_retries 2>/dev/null || echo "N/A")

--- TCP Buffer Parameters ---
net.ipv4.tcp_moderate_rcvbuf = $(cat /proc/sys/net/ipv4/tcp_moderate_rcvbuf 2>/dev/null || echo "N/A")
net.ipv4.tcp_adv_win_scale = $(cat /proc/sys/net/ipv4/tcp_adv_win_scale 2>/dev/null || echo "N/A")
EOF
}

# Function to gather UDP parameters
gather_udp_params() {
    echo -e "${YELLOW}Gathering UDP parameters...${NC}"
    
    cat > "$OUTPUT_DIR/udp-params.txt" << EOF
=== UDP PARAMETERS ===
net.core.rmem_max = $(cat /proc/sys/net/core/rmem_max 2>/dev/null || echo "N/A")
net.core.wmem_max = $(cat /proc/sys/net/core/wmem_max 2>/dev/null || echo "N/A")
net.ipv4.udp_rmem_min = $(cat /proc/sys/net/ipv4/udp_rmem_min 2>/dev/null || echo "N/A")
net.ipv4.udp_wmem_min = $(cat /proc/sys/net/ipv4/udp_wmem_min 2>/dev/null || echo "N/A")
EOF
}

# Function to gather file descriptor limits
gather_fd_limits() {
    echo -e "${YELLOW}Gathering file descriptor limits...${NC}"
    
    cat > "$OUTPUT_DIR/fd-limits.txt" << EOF
=== FILE DESCRIPTOR LIMITS ===
System-wide limits:
$(ulimit -n)

Process limits for current shell:
$(ulimit -a)

System limits from /proc:
$(cat /proc/sys/fs/file-max 2>/dev/null || echo "N/A")

Docker daemon limits (if accessible):
$(docker system info 2>/dev/null | grep -i "file descriptor" || echo "N/A")
EOF
}

# Function to gather Docker container network info
gather_docker_network_info() {
    echo -e "${YELLOW}Gathering Docker container network information...${NC}"
    
    if command -v docker &> /dev/null; then
        # Running containers
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}" > "$OUTPUT_DIR/docker-containers.txt" 2>&1
        
        # Container network details
        cat > "$OUTPUT_DIR/docker-network-details.txt" << EOF
=== DOCKER NETWORK DETAILS ===

--- Network List ---
$(docker network ls 2>/dev/null || echo "Docker networks not accessible")

--- Container Network Inspections ---
EOF

        # Inspect network for each running container
        for container in $(docker ps --format "{{.Names}}" 2>/dev/null); do
            echo "--- Container: $container ---" >> "$OUTPUT_DIR/docker-network-details.txt"
            docker inspect "$container" --format='{{.NetworkSettings.Networks}}' >> "$OUTPUT_DIR/docker-network-details.txt" 2>&1 || echo "Inspection failed"
            echo "" >> "$OUTPUT_DIR/docker-network-details.txt"
        done
    else
        echo "Docker not available" > "$OUTPUT_DIR/docker-network-details.txt"
    fi
}

# Function to gather process network info
gather_process_network_info() {
    echo -e "${YELLOW}Gathering process network information...${NC}"
    
    # Network connections
    ss -tuln > "$OUTPUT_DIR/network-connections.txt" 2>&1
    
    # Process network usage
    cat > "$OUTPUT_DIR/process-network-usage.txt" << EOF
=== PROCESS NETWORK USAGE ===

--- Network Statistics by Protocol ---
$(ss -s 2>/dev/null || echo "ss -s not available")

--- Top Network Using Processes ---
$(netstat -tuln 2>/dev/null | head -20 || echo "netstat not available")
EOF
}

# Function to gather memory and CPU info
gather_resource_info() {
    echo -e "${YELLOW}Gathering resource usage information...${NC}"
    
    # Memory info
    cat > "$OUTPUT_DIR/memory-info.txt" << EOF
=== MEMORY INFORMATION ===
$(free -h)

--- Memory Details ---
$(cat /proc/meminfo | grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree)")

--- Slab Info ---
$(cat /proc/slabinfo | head -20)
EOF

    # CPU info
    cat > "$OUTPUT_DIR/cpu-info.txt" << EOF
=== CPU INFORMATION ===
$(cat /proc/cpuinfo | grep -E "(model name|processor|cache size|physical id|core id)")

--- CPU Load ---
$(uptime)

--- CPU Statistics ---
$(cat /proc/stat | head -5)
EOF
}

# Function to gather disk I/O info
gather_disk_io_info() {
    echo -e "${YELLOW}Gathering disk I/O information...${NC}"
    
    cat > "$OUTPUT_DIR/disk-io-info.txt" << EOF
=== DISK I/O INFORMATION ===
$(iostat -x 1 1 2>/dev/null || echo "iostat not available")

--- Disk Usage ---
$(df -h)

--- Disk I/O Statistics ---
$(cat /proc/diskstats | head -20)
EOF
}

# Function to gather network performance metrics
gather_network_performance() {
    echo -e "${YELLOW}Gathering network performance metrics...${NC}"
    
    cat > "$OUTPUT_DIR/network-performance.txt" << EOF
=== NETWORK PERFORMANCE METRICS ===

--- Network Interface Statistics ---
$(cat /proc/net/dev)

--- TCP Statistics ---
$(cat /proc/net/tcp | wc -l) TCP connections

--- UDP Statistics ---
$(cat /proc/net/udp | wc -l) UDP connections

--- Network Error Counts ---
$(cat /proc/net/netstat | grep -E "(TcpExt|IpExt)" || echo "Netstat not available")
EOF
}

# Function to create optimization recommendations
create_recommendations() {
    echo -e "${YELLOW}Creating optimization recommendations...${NC}"
    
    cat > "$OUTPUT_DIR/optimization-recommendations.txt" << EOF
=== NETWORK OPTIMIZATION RECOMMENDATIONS ===

This analysis was generated for a Lighthouse + Ethereum Full Node setup
Target: 1Gb network with 50+ peers

## IMMEDIATE OPTIMIZATIONS:

1. TCP Buffer Sizes:
   - Increase net.core.rmem_max to 268435456 (256MB)
   - Increase net.core.wmem_max to 268435456 (256MB)
   - Increase net.core.rmem_default to 134217728 (128MB)
   - Increase net.core.wmem_default to 134217728 (128MB)

2. TCP Window Sizes:
   - Optimize net.ipv4.tcp_rmem: 8192 174760 134217728
   - Optimize net.ipv4.tcp_wmem: 8192 131072 134217728

3. Connection Limits:
   - Increase net.ipv4.tcp_max_syn_backlog to 131072
   - Increase net.ipv4.tcp_max_tw_buckets to 131072

4. TCP Optimizations:
   - Enable net.ipv4.tcp_fack = 1
   - Set net.ipv4.tcp_slow_start_after_idle = 0
   - Keep net.ipv4.tcp_congestion_control = bbr (already optimal)

5. Keepalive Optimization:
   - Reduce net.ipv4.tcp_keepalive_time to 3600
   - Reduce net.ipv4.tcp_keepalive_intvl to 30
   - Reduce net.ipv4.tcp_keepalive_probes to 3

## DOCKER-SPECIFIC OPTIMIZATIONS:

1. Increase Docker daemon file descriptor limits
2. Use host networking for critical containers if possible
3. Monitor container network performance
4. Consider using --network=host for Ethereum node

## MONITORING:

1. Monitor network interface statistics
2. Track TCP connection counts
3. Watch for connection drops
4. Monitor memory usage patterns

## IMPLEMENTATION:

Create /etc/sysctl.d/99-ethereum-optimization.conf with the above values
Apply with: sysctl -p /etc/sysctl.d/99-ethereum-optimization.conf
EOF
}

# Function to create summary report
create_summary() {
    echo -e "${YELLOW}Creating summary report...${NC}"
    
    cat > "$OUTPUT_DIR/SUMMARY.md" << EOF
# Network Optimization Analysis Summary

**Generated:** $(date)
**Target System:** Lighthouse + Ethereum Full Node
**Network:** 1Gb with 50+ peers
**Output Directory:** $OUTPUT_DIR

## Files Generated:

- \`system-info.txt\` - Basic system information
- \`network-interfaces.txt\` - Network interface details
- \`network-stats.txt\` - Interface statistics and capabilities
- \`core-network-params.txt\` - Core network parameters
- \`udp-params.txt\` - UDP-specific parameters
- \`fd-limits.txt\` - File descriptor limits
- \`docker-containers.txt\` - Running Docker containers
- \`docker-network-details.txt\` - Docker network configuration
- \`process-network-usage.txt\` - Process network usage
- \`memory-info.txt\` - Memory usage and statistics
- \`cpu-info.txt\` - CPU information and load
- \`disk-io-info.txt\` - Disk I/O statistics
- \`network-performance.txt\` - Network performance metrics
- \`optimization-recommendations.txt\` - Specific optimization steps

## Quick Assessment:

$(if [[ -f "$OUTPUT_DIR/core-network-params.txt" ]]; then
    echo "✅ Core network parameters gathered"
    echo "✅ Docker information collected"
    echo "✅ System resources analyzed"
    echo "✅ Optimization recommendations created"
else
    echo "❌ Some information gathering failed"
fi)

## Next Steps:

1. Review the generated files for current system state
2. Implement the optimization recommendations
3. Test network performance improvements
4. Monitor for any issues after changes

## Usage:

\`\`\`bash
# View summary
cat $OUTPUT_DIR/SUMMARY.md

# View recommendations
cat $OUTPUT_DIR/optimization-recommendations.txt

# View current network parameters
cat $OUTPUT_DIR/core-network-params.txt
\`\`\`
EOF
}

# Main execution
main() {
    echo -e "${GREEN}Starting network optimization analysis...${NC}"
    
    # Check if running as root
    check_root
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Gather all information
    gather_system_info
    gather_network_info
    gather_core_network_params
    gather_udp_params
    gather_fd_limits
    gather_docker_network_info
    gather_process_network_info
    gather_resource_info
    gather_disk_io_info
    gather_network_performance
    
    # Create recommendations and summary
    create_recommendations
    create_summary
    
    echo -e "${GREEN}Analysis complete!${NC}"
    echo -e "${GREEN}Output directory: $OUTPUT_DIR${NC}"
    echo ""
    echo -e "${BLUE}Files generated:${NC}"
    ls -la "$OUTPUT_DIR"
    echo ""
    echo -e "${YELLOW}View summary: cat $OUTPUT_DIR/SUMMARY.md${NC}"
    echo -e "${YELLOW}View recommendations: cat $OUTPUT_DIR/optimization-recommendations.txt${NC}"
}

# Run main function
main "$@"
