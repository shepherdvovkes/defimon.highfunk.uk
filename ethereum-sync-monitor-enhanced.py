#!/usr/bin/env python3
"""
Enhanced Ethereum Sync Monitor - Rich CLI Tool
Monitors geth and lighthouse sync status with detailed progress information
"""

import json
import time
import requests
import psutil
import os
import sys
from datetime import datetime, timedelta
from typing import Dict, Optional, Tuple, List
import argparse
from collections import deque
from rich.console import Console
from rich.layout import Layout
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn, TimeRemainingColumn
from rich.table import Table
from rich.text import Text
from rich.live import Live
from rich.columns import Columns
from rich.align import Align

class EnhancedEthereumSyncMonitor:
    def __init__(self, geth_port: int = 8545, lighthouse_port: int = 5052, 
                 geth_data_path: str = "./geth-data", 
                 lighthouse_data_path: str = "./lighthouse-data"):
        self.geth_port = geth_port
        self.lighthouse_port = lighthouse_port
        self.geth_data_path = geth_data_path
        self.lighthouse_data_path = lighthouse_data_path
        self.session = requests.Session()
        self.session.timeout = 5
        self.console = Console()
        
        # Historical data for rate calculations
        self.geth_block_history = deque(maxlen=3600)  # Store 1 hour of data (3600 seconds)
        self.lighthouse_slot_history = deque(maxlen=3600)
        self.network_history = deque(maxlen=3600)
        
        # Initialize network counters
        self.last_network_stats = None
        self.last_network_time = time.time()
        
    def get_geth_sync_status(self) -> Optional[Dict]:
        """Get geth sync status via JSON-RPC"""
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_syncing",
                "params": [],
                "id": 1
            }
            response = self.session.post(
                f"http://localhost:{self.geth_port}",
                json=payload,
                headers={"Content-Type": "application/json"}
            )
            if response.status_code == 200:
                result = response.json()
                if "result" in result:
                    return result["result"]
            return None
        except Exception as e:
            self.console.print(f"Geth sync status error: {e}", style="red")
            return None
    
    def get_geth_block_number(self) -> Optional[int]:
        """Get current geth block number"""
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }
            response = self.session.post(
                f"http://localhost:{self.geth_port}",
                json=payload,
                headers={"Content-Type": "application/json"}
            )
            if response.status_code == 200:
                result = response.json()
                if "result" in result:
                    return int(result["result"], 16)
            return None
        except Exception as e:
            self.console.print(f"Geth block number error: {e}", style="red")
            return None
    
    def get_geth_peer_count(self) -> Optional[int]:
        """Get geth peer count"""
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": "net_peerCount",
                "params": [],
                "id": 1
            }
            response = self.session.post(
                f"http://localhost:{self.geth_port}",
                json=payload,
                headers={"Content-Type": "application/json"}
            )
            if response.status_code == 200:
                result = response.json()
                if "result" in result:
                    return int(result["result"], 16)
            return None
        except Exception as e:
            self.console.print(f"Geth peer count error: {e}", style="red")
            return None
    
    def get_geth_chain_head(self) -> Optional[Dict]:
        """Get geth chain head information"""
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_getBlockByNumber",
                "params": ["latest", False],
                "id": 1
            }
            response = self.session.post(
                f"http://localhost:{self.geth_port}",
                json=payload,
                headers={"Content-Type": "application/json"}
            )
            if response.status_code == 200:
                result = response.json()
                if "result" in result:
                    return result["result"]
            return None
        except Exception as e:
            self.console.print(f"Geth chain head error: {e}", style="red")
            return None
    
    def get_lighthouse_sync_status(self) -> Optional[Dict]:
        """Get lighthouse sync status via REST API"""
        try:
            response = self.session.get(f"http://localhost:{self.lighthouse_port}/eth/v1/node/syncing")
            if response.status_code == 200:
                return response.json().get("data", {})
            return None
        except Exception as e:
            self.console.print(f"Lighthouse sync status error: {e}", style="red")
            return None
    
    def get_lighthouse_head_slot(self) -> Optional[int]:
        """Get lighthouse head slot"""
        try:
            response = self.session.get(f"http://localhost:{self.lighthouse_port}/eth/v1/beacon/headers")
            if response.status_code == 200:
                data = response.json().get("data", [])
                if data:
                    return int(data[0].get("header", {}).get("message", {}).get("slot", "0"))
            return None
        except Exception as e:
            self.console.print(f"Lighthouse head slot error: {e}", style="red")
            return None
    
    def get_lighthouse_finalized_slot(self) -> Optional[int]:
        """Get lighthouse finalized slot"""
        try:
            response = self.session.get(f"http://localhost:{self.lighthouse_port}/eth/v1/beacon/states/finalized/finality_checkpoints")
            if response.status_code == 200:
                data = response.json().get("data", {})
                if data:
                    return int(data.get("finalized", {}).get("epoch", "0")) * 32
            return None
        except Exception as e:
            self.console.print(f"Lighthouse finalized slot error: {e}", style="red")
            return None
    
    def get_network_interfaces(self) -> Dict:
        """Get detailed network interface information"""
        try:
            interfaces = {}
            net_io = psutil.net_io_counters(pernic=True)
            net_addrs = psutil.net_if_addrs()
            
            for interface_name, stats in net_io.items():
                if interface_name in net_addrs:
                    # Get interface addresses
                    addrs = net_addrs[interface_name]
                    ip_addr = "N/A"
                    for addr in addrs:
                        if addr.family == 2:  # AF_INET (IPv4)
                            ip_addr = addr.address
                            break
                    
                    interfaces[interface_name] = {
                        'bytes_sent': stats.bytes_sent,
                        'bytes_recv': stats.bytes_recv,
                        'packets_sent': stats.packets_sent,
                        'packets_recv': stats.packets_recv,
                        'ip_address': ip_addr
                    }
            
            return interfaces
        except Exception as e:
            self.console.print(f"Network interfaces error: {e}", style="red")
            return {}
    
    def calculate_sync_rates(self, history: deque, current_value: int, current_time: float) -> Dict:
        """Calculate sync rates for different time periods"""
        if not history:
            return {'10s': 0, '10m': 0, '10h': 0}
        
        rates = {}
        current_time = int(current_time)
        
        # Calculate rates for different time periods
        for period, seconds in [('10s', 10), ('10m', 600), ('10h', 36000)]:
            if len(history) > 0:
                # Find the oldest entry within the time period
                period_start = current_time - seconds
                period_entries = [entry for entry in history if entry['timestamp'] >= period_start]
                
                if len(period_entries) >= 2:
                    oldest = period_entries[0]['value']
                    newest = period_entries[-1]['value']
                    time_diff = period_entries[-1]['timestamp'] - period_entries[0]['timestamp']
                    
                    if time_diff > 0:
                        rate = (newest - oldest) / time_diff
                        rates[period] = rate
                    else:
                        rates[period] = 0
                else:
                    rates[period] = 0
            else:
                rates[period] = 0
        
        return rates
    
    def calculate_network_bandwidth(self, current_stats: Dict, last_stats: Dict, time_diff: float) -> Dict:
        """Calculate network bandwidth for each interface"""
        bandwidth = {}
        
        for interface_name, current in current_stats.items():
            if interface_name in last_stats:
                last = last_stats[interface_name]
                
                # Calculate bytes per second
                bytes_sent_diff = current['bytes_sent'] - last['bytes_sent']
                bytes_recv_diff = current['bytes_recv'] - last['bytes_recv']
                
                # Calculate bandwidth in Mbps
                sent_mbps = (bytes_sent_diff * 8) / (time_diff * 1000000)
                recv_mbps = (bytes_recv_diff * 8) / (time_diff * 1000000)
                
                bandwidth[interface_name] = {
                    'sent_mbps': sent_mbps,
                    'recv_mbps': recv_mbps,
                    'sent_bytes': bytes_sent_diff,
                    'recv_bytes': bytes_recv_diff,
                    'ip_address': current['ip_address']
                }
        
        return bandwidth
    
    def update_historical_data(self, geth_block: Optional[int], lighthouse_slot: Optional[int]):
        """Update historical data for rate calculations"""
        current_time = time.time()
        
        if geth_block is not None:
            self.geth_block_history.append({
                'timestamp': current_time,
                'value': geth_block
            })
        
        if lighthouse_slot is not None:
            self.lighthouse_slot_history.append({
                'timestamp': current_time,
                'value': lighthouse_slot
            })
        
        # Update network stats
        current_network = self.get_network_interfaces()
        if self.last_network_stats is not None:
            time_diff = current_time - self.last_network_time
            if time_diff > 0:
                bandwidth = self.calculate_network_bandwidth(current_network, self.last_network_stats, time_diff)
                self.network_history.append({
                    'timestamp': current_time,
                    'bandwidth': bandwidth
                })
        
        self.last_network_stats = current_network
        self.last_network_time = current_time
    
    def get_directory_size(self, path: str) -> int:
        """Get directory size in bytes"""
        try:
            if os.path.exists(path):
                total_size = 0
                for dirpath, dirnames, filenames in os.walk(path):
                    for filename in filenames:
                        filepath = os.path.join(dirpath, filename)
                        if os.path.exists(filepath):
                            total_size += os.path.getsize(filepath)
                return total_size
        except Exception:
            pass
        return 0
    
    def format_bytes(self, bytes_value: int) -> str:
        """Format bytes to human readable format"""
        if bytes_value == 0:
            return "0 B"
        size_names = ["B", "KB", "MB", "GB", "TB"]
        i = 0
        while bytes_value >= 1024 and i < len(size_names) - 1:
            bytes_value /= 1024.0
            i += 1
        return f"{bytes_value:.1f} {size_names[i]}"
    
    def format_bandwidth(self, mbps: float) -> str:
        """Format bandwidth to human readable format"""
        if mbps < 1:
            return f"{mbps * 1000:.1f} Kbps"
        elif mbps < 1000:
            return f"{mbps:.1f} Mbps"
        else:
            return f"{mbps / 1000:.1f} Gbps"
    
    def format_time(self, seconds: int) -> str:
        """Format seconds to human readable time"""
        if seconds < 60:
            return f"{seconds}s"
        elif seconds < 3600:
            minutes = seconds // 60
            seconds = seconds % 60
            return f"{minutes}m {seconds}s"
        else:
            hours = seconds // 3600
            minutes = (seconds % 3600) // 60
            return f"{hours}h {minutes}m"
    
    def calculate_sync_progress(self, current: int, target: int) -> float:
        """Calculate sync progress percentage"""
        if target == 0:
            return 0.0
        return min(100.0, (current / target) * 100)
    
    def create_geth_detailed_panel(self, progress: Progress) -> Panel:
        """Create detailed geth status panel with progress bar and sync rates"""
        geth_sync = self.get_geth_sync_status()
        geth_block = self.get_geth_block_number()
        geth_peers = self.get_geth_peer_count()
        geth_chain_head = self.get_geth_chain_head()
        geth_size = self.get_directory_size(self.geth_data_path)
        
        # Calculate sync rates
        geth_rates = self.calculate_sync_rates(self.geth_block_history, geth_block or 0, time.time())
        
        # Ensure proper type conversion for geth_peers
        if isinstance(geth_peers, str):
            geth_peers = int(geth_peers) if geth_peers.isdigit() else 0
        
        # Create progress bar for geth
        if geth_sync and isinstance(geth_sync, dict):
            current_block = int(geth_sync.get("currentBlock", "0x0"), 16)
            highest_block = int(geth_sync.get("highestBlock", "0x0"), 16)
            
            if highest_block > 0:
                # Update or create progress bar
                task_id = progress.add_task("Geth Sync", total=highest_block)
                progress.update(task_id, completed=current_block)
                
                remaining_blocks = highest_block - current_block
                progress_percent = self.calculate_sync_progress(current_block, highest_block)
                
                # Estimate sync time (rough calculation)
                if geth_peers and geth_peers > 0:
                    # Rough estimate: 1 block per second with good peer count
                    estimated_seconds = remaining_blocks
                    eta = self.format_time(estimated_seconds)
                else:
                    eta = "Unknown"
                
                content = f"""
Current Block: {current_block:,}
Target Block: {highest_block:,}
Remaining: {remaining_blocks:,} blocks
Progress: {progress_percent:.2f}%
ETA: {eta}
Connected Peers: {geth_peers or 'Unknown'}
Data Size: {self.format_bytes(geth_size)}

Sync Rates:
10s: {geth_rates['10s']:.1f} blocks/s
10m: {geth_rates['10m']:.1f} blocks/s
10h: {geth_rates['10h']:.1f} blocks/s
                """.strip()
            else:
                content = f"""
Status: Initializing sync...
Current Block: Starting...
Connected Peers: {geth_peers or 'Unknown'}
Data Size: {self.format_bytes(geth_size)}

Sync Rates:
10s: {geth_rates['10s']:.1f} blocks/s
10m: {geth_rates['10m']:.1f} blocks/s
10h: {geth_rates['10h']:.1f} blocks/s
                """.strip()
        else:
            # Try to get basic block info if sync status fails
            if geth_block is not None:
                content = f"""
Status: Not actively syncing
Current Block: {geth_block:,}
Connected Peers: {geth_peers or 'Unknown'}
Data Size: {self.format_bytes(geth_size)}

Sync Rates:
10s: {geth_rates['10s']:.1f} blocks/s
10m: {geth_rates['10m']:.1f} blocks/s
10h: {geth_rates['10h']:.1f} blocks/s
                """.strip()
            else:
                content = f"""
Status: Not syncing or error
Connected Peers: {geth_peers or 'Unknown'}
Data Size: {self.format_bytes(geth_size)}

Sync Rates:
10s: {geth_rates['10s']:.1f} blocks/s
10m: {geth_rates['10m']:.1f} blocks/s
10h: {geth_rates['10h']:.1f} blocks/s
                """.strip()
        
        return Panel(content, title="GETH (Execution Layer)", border_style="blue")
    
    def create_lighthouse_detailed_panel(self, progress: Progress) -> Panel:
        """Create detailed lighthouse status panel with progress bar and sync rates"""
        lighthouse_sync = self.get_lighthouse_sync_status()
        lighthouse_head = self.get_lighthouse_head_slot()
        lighthouse_finalized = self.get_lighthouse_finalized_slot()
        lighthouse_size = self.get_directory_size(self.lighthouse_data_path)
        
        # Calculate sync rates
        lighthouse_rates = self.calculate_sync_rates(self.lighthouse_slot_history, lighthouse_head or 0, time.time())
        
        if lighthouse_sync:
            is_syncing = lighthouse_sync.get("is_syncing", False)
            head_slot = lighthouse_sync.get("head_slot", 0)
            sync_distance = lighthouse_sync.get("sync_distance", 0)
            is_optimistic = lighthouse_sync.get("is_optimistic", False)
            el_offline = lighthouse_sync.get("el_offline", False)
            
            if isinstance(head_slot, str):
                head_slot = int(head_slot)
            if isinstance(sync_distance, str):
                sync_distance = int(sync_distance)
            
            # Create progress bar for lighthouse
            if sync_distance > 0:
                # Estimate total slots (rough approximation)
                estimated_total = head_slot + sync_distance
                task_id = progress.add_task("Lighthouse Sync", total=estimated_total)
                progress.update(task_id, completed=head_slot)
                
                estimated_seconds = sync_distance * 12  # 12 seconds per slot
                progress_percent = self.calculate_sync_progress(head_slot, estimated_total)
                
                content = f"""
Current Slot: {head_slot:,}
Sync Distance: {sync_distance:,} slots
Progress: {progress_percent:.2f}%
Syncing: {'Yes' if is_syncing else 'No'}
Optimistic: {'Yes' if is_optimistic else 'No'}
EL Connected: {'No' if el_offline else 'Yes'}
Estimated Time: {self.format_time(estimated_seconds)}
Data Size: {self.format_bytes(lighthouse_size)}

Sync Rates:
10s: {lighthouse_rates['10s']:.1f} slots/s
10m: {lighthouse_rates['10m']:.1f} slots/s
10h: {lighthouse_rates['10h']:.1f} slots/s
                """.strip()
            else:
                content = f"""
Current Slot: {head_slot:,}
Sync Distance: 0 slots (Synced!)
Progress: 100.00%
Syncing: {'Yes' if is_syncing else 'No'}
Optimistic: {'Yes' if is_optimistic else 'No'}
EL Connected: {'No' if el_offline else 'Yes'}
Data Size: {self.format_bytes(lighthouse_size)}

Sync Rates:
10s: {lighthouse_rates['10s']:.1f} slots/s
10m: {lighthouse_rates['10m']:.1f} slots/s
10h: {lighthouse_rates['10h']:.1f} slots/s
                """.strip()
        else:
            content = f"""
Status: Error or not responding
Data Size: {self.format_bytes(lighthouse_size)}

Sync Rates:
10s: {lighthouse_rates['10s']:.1f} slots/s
10m: {lighthouse_rates['10m']:.1f} slots/s
10h: {lighthouse_rates['10h']:.1f} slots/s
                """.strip()
        
        return Panel(content, title="LIGHTHOUSE (Consensus Layer)", border_style="yellow")
    
    def create_network_panel(self) -> Panel:
        """Create network interface bandwidth panel"""
        try:
            current_network = self.get_network_interfaces()
            
            if not current_network:
                return Panel("No network interfaces found", title="NETWORK BANDWIDTH", border_style="red")
            
            # Calculate current bandwidth if we have historical data
            current_time = time.time()
            bandwidth_info = {}
            
            if self.last_network_stats is not None and self.last_network_time > 0:
                time_diff = current_time - self.last_network_time
                if time_diff > 0:
                    bandwidth_info = self.calculate_network_bandwidth(current_network, self.last_network_stats, time_diff)
            
            content_lines = []
            for interface_name, stats in current_network.items():
                content_lines.append(f"Interface: {interface_name}")
                content_lines.append(f"IP: {stats['ip_address']}")
                
                if interface_name in bandwidth_info:
                    bw = bandwidth_info[interface_name]
                    content_lines.append(f"TX: {self.format_bandwidth(bw['sent_mbps'])}")
                    content_lines.append(f"RX: {self.format_bandwidth(bw['recv_mbps'])}")
                    content_lines.append(f"Total TX: {self.format_bytes(stats['bytes_sent'])}")
                    content_lines.append(f"Total RX: {self.format_bytes(stats['bytes_recv'])}")
                else:
                    content_lines.append(f"Total TX: {self.format_bytes(stats['bytes_sent'])}")
                    content_lines.append(f"Total RX: {self.format_bytes(stats['bytes_recv'])}")
                    content_lines.append("Bandwidth: Calculating...")
                
                content_lines.append("")  # Empty line between interfaces
            
            content = "\n".join(content_lines).strip()
            
        except Exception as e:
            content = f"Network info error: {e}"
        
        return Panel(content, title="NETWORK BANDWIDTH", border_style="cyan")
    
    def create_system_detailed_panel(self) -> Panel:
        """Create detailed system info panel"""
        try:
            # Get disk usage for the current directory
            disk_usage = psutil.disk_usage(".")
            total = disk_usage.total
            used = disk_usage.used
            free = disk_usage.free
            
            # Get memory usage
            memory = psutil.virtual_memory()
            
            # Get CPU usage
            cpu_percent = psutil.cpu_percent(interval=0.1)
            
            # Get network info
            network = psutil.net_io_counters()
            
            content = f"""
Total Disk: {self.format_bytes(total)}
Used: {self.format_bytes(used)}
Free: {self.format_bytes(free)}
Memory Used: {self.format_bytes(memory.used)} / {self.format_bytes(memory.total)} ({memory.percent:.1f}%)
CPU Usage: {cpu_percent:.1f}%
Network Sent: {self.format_bytes(network.bytes_sent)}
Network Recv: {self.format_bytes(network.bytes_recv)}
            """.strip()
            
        except Exception as e:
            content = f"System info error: {e}"
        
        return Panel(content, title="SYSTEM INFO", border_style="green")
    
    def create_sync_summary_table(self) -> Table:
        """Create a comprehensive sync summary table"""
        table = Table(title="Ethereum Node Sync Summary", show_header=True, header_style="bold magenta")
        table.add_column("Metric", style="cyan", width=20)
        table.add_column("Geth", style="blue", width=25)
        table.add_column("Lighthouse", style="yellow", width=25)
        table.add_column("Status", style="green", width=15)
        
        # Geth metrics
        geth_sync = self.get_geth_sync_status()
        geth_block = self.get_geth_block_number()
        geth_peers = self.get_geth_peer_count()
        
        if geth_sync and isinstance(geth_sync, dict):
            current_block = int(geth_sync.get("currentBlock", "0x0"), 16)
            highest_block = int(geth_sync.get("highestBlock", "0x0"), 16)
            if highest_block > 0:
                remaining_blocks = highest_block - current_block
                progress = self.calculate_sync_progress(current_block, highest_block)
                geth_status = f"Block {current_block:,}/{highest_block:,}"
                geth_progress = f"{progress:.1f}% ({remaining_blocks:,} left)"
            else:
                geth_status = "Initializing"
                geth_progress = "Starting sync"
        else:
            geth_status = f"Block {geth_block:,}" if geth_block else "Unknown"
            geth_progress = "Not syncing"
        
        # Lighthouse metrics
        lighthouse_sync = self.get_lighthouse_sync_status()
        if lighthouse_sync:
            head_slot = lighthouse_sync.get("head_slot", 0)
            sync_distance = lighthouse_sync.get("sync_distance", 0)
            if isinstance(head_slot, str):
                head_slot = int(head_slot)
            if isinstance(sync_distance, str):
                sync_distance = int(sync_distance)
            
            if sync_distance > 0:
                lighthouse_status = f"Slot {head_slot:,}"
                lighthouse_progress = f"Syncing (+{sync_distance})"
            else:
                lighthouse_status = f"Slot {head_slot:,}"
                lighthouse_progress = "Synced"
        else:
            lighthouse_status = "Unknown"
            lighthouse_progress = "Error"
        
        # Overall status
        if geth_sync and lighthouse_sync:
            # Ensure proper type conversion for comparisons
            geth_current = geth_sync.get("currentBlock", "0x0")
            lighthouse_distance = lighthouse_sync.get("sync_distance", 0)
            
            # Convert to appropriate types if needed
            if isinstance(lighthouse_distance, str):
                lighthouse_distance = int(lighthouse_distance) if lighthouse_distance.isdigit() else 0
            
            overall_status = "🟢 Both Syncing" if (geth_current != "0x0" or lighthouse_distance > 0) else "🟡 Synced"
        else:
            overall_status = "🔴 Error"
        
        table.add_row("Current Position", geth_status, lighthouse_status, overall_status)
        table.add_row("Sync Progress", geth_progress, lighthouse_progress, "")
        table.add_row("Connected Peers", str(geth_peers or "Unknown"), "-", "")
        
        return table
    
    def create_initial_layout(self):
        """Create initial layout for Live display"""
        return Panel("Initializing Ethereum Sync Monitor...", title="Loading", style="bold blue")
    
    def create_display_layout(self, layout: Layout, progress: Progress):
        """Create the final display layout with progress bars"""
        # Create a container that includes both layout and progress
        from rich.containers import Renderables
        
        # Combine layout and progress in a column
        display = Layout()
        display.split_column(
            Layout(name="main_content"),
            Layout(name="progress_section", size=3)
        )
        
        display["main_content"].update(layout)
        display["progress_section"].update(progress)
        
        return display
    
    def create_simple_display(self, geth_panel: Panel, lighthouse_panel: Panel, 
                             system_panel: Panel, network_panel: Panel, 
                             summary_table: Table, progress: Progress):
        """Create a simple display without complex layouts to avoid black screen"""
        from rich.columns import Columns
        
        # Create a simple column-based layout
        panels = [
            geth_panel,
            lighthouse_panel,
            system_panel,
            network_panel
        ]
        
        # Use Columns for simple layout
        columns = Columns(panels, equal=True, expand=True)
        
        # Return a simple structure
        return Panel(
            f"{columns}\n\n{summary_table}\n\n{progress}",
            title=f"Enhanced Ethereum Sync Monitor - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            style="bold blue"
        )
    
    def run_monitor(self, refresh_interval: int = 3):
        """Run the enhanced monitor with live updates"""
        console = Console()
        
        # Use Live instead of screen() to avoid black screen issues
        with Live(
            self.create_initial_layout(),
            refresh_per_second=4,
            screen=True
        ) as live:
            while True:
                try:
                    # Get current data and update historical records
                    geth_block = self.get_geth_block_number()
                    lighthouse_slot = self.get_lighthouse_head_slot()
                    self.update_historical_data(geth_block, lighthouse_slot)
                    
                    # Create progress bars
                    progress = Progress(
                        SpinnerColumn(),
                        TextColumn("[progress.description]{task.description}"),
                        BarColumn(),
                        TaskProgressColumn(),
                        TimeRemainingColumn(),
                        console=console
                    )
                    
                    # Create layout
                    layout = Layout()
                    layout.split_column(
                        Layout(name="header", size=3),
                        Layout(name="main"),
                        Layout(name="footer", size=3)
                    )
                    
                    layout["main"].split_row(
                        Layout(name="left"),
                        Layout(name="right")
                    )
                    
                    layout["left"].split_column(
                        Layout(name="geth"),
                        Layout(name="lighthouse")
                    )
                    
                    layout["right"].split_column(
                        Layout(name="system"),
                        Layout(name="network"),
                        Layout(name="summary")
                    )
                    
                    # Header with timestamp
                    header = Panel(
                        f"Enhanced Ethereum Sync Monitor - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
                        style="bold blue"
                    )
                    
                    # Create panels
                    geth_panel = self.create_geth_detailed_panel(progress)
                    lighthouse_panel = self.create_lighthouse_detailed_panel(progress)
                    system_panel = self.create_system_detailed_panel()
                    network_panel = self.create_network_panel()
                    summary_table = self.create_sync_summary_table()
                    
                    # Layout panels - use safe updates
                    try:
                        layout["header"].update(header)
                        layout["geth"].update(geth_panel)
                        layout["lighthouse"].update(lighthouse_panel)
                        layout["system"].update(system_panel)
                        layout["network"].update(network_panel)
                        layout["summary"].update(summary_table)
                    except Exception as layout_error:
                        console.print(f"Layout update error: {layout_error}", style="red")
                    
                    # Footer with controls
                    footer = Panel(
                        "Press Ctrl+C to exit | Auto-refresh every {} seconds | Real-time sync rates & network bandwidth".format(refresh_interval),
                        style="dim"
                    )
                    layout["footer"].update(footer)
                    
                    # Update live display instead of clearing console
                    try:
                        # Try complex layout first
                        display_layout = self.create_display_layout(layout, progress)
                        live.update(display_layout)
                    except Exception as display_error:
                        # Fallback to simple display if complex layout fails
                        console.print(f"Complex layout failed, using simple display: {display_error}", style="yellow")
                        simple_display = self.create_simple_display(
                            geth_panel, lighthouse_panel, system_panel, 
                            network_panel, summary_table, progress
                        )
                        live.update(simple_display)
                    
                    time.sleep(refresh_interval)
                    
                except KeyboardInterrupt:
                    console.print("\nMonitor stopped. Goodbye!")
                    break
                except Exception as e:
                    console.print(f"\nError: {e}", style="bold red")
                    time.sleep(refresh_interval)
    
    def run_simple_monitor(self, refresh_interval: int = 3):
        """Run a simple monitor without complex layouts to avoid black screen issues"""
        console = Console()
        
        console.print("Starting Simple Ethereum Sync Monitor...", style="bold green")
        console.print("This version avoids complex layouts to prevent display issues", style="bold cyan")
        
        while True:
            try:
                # Clear screen manually
                os.system('clear' if os.name == 'posix' else 'cls')
                
                # Get current data
                geth_block = self.get_geth_block_number()
                lighthouse_slot = self.get_lighthouse_head_slot()
                self.update_historical_data(geth_block, lighthouse_slot)
                
                # Create progress bars
                progress = Progress(
                    SpinnerColumn(),
                    TextColumn("[progress.description]{task.description}"),
                    BarColumn(),
                    TaskProgressColumn(),
                    TimeRemainingColumn(),
                    console=console
                )
                
                # Create panels
                geth_panel = self.create_geth_detailed_panel(progress)
                lighthouse_panel = self.create_lighthouse_detailed_panel(progress)
                system_panel = self.create_system_detailed_panel()
                network_panel = self.create_network_panel()
                summary_table = self.create_sync_summary_table()
                
                # Display everything
                console.print(f"\n[bold blue]Enhanced Ethereum Sync Monitor - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}[/bold blue]\n")
                
                # Use simple columns layout
                from rich.columns import Columns
                panels = [geth_panel, lighthouse_panel, system_panel, network_panel]
                columns = Columns(panels, equal=True, expand=True)
                
                console.print(columns)
                console.print("\n")
                console.print(summary_table)
                console.print("\n")
                console.print(progress)
                
                console.print(f"\n[dim]Press Ctrl+C to exit | Auto-refresh every {refresh_interval} seconds[/dim]")
                
                time.sleep(refresh_interval)
                
            except KeyboardInterrupt:
                console.print("\nMonitor stopped. Goodbye!")
                break
            except Exception as e:
                console.print(f"\nError: {e}", style="bold red")
                time.sleep(refresh_interval)
    
    def run_simple_monitor(self, refresh_interval: int = 3):
        """Run a simple monitor without complex layouts to avoid black screen issues"""
        console = Console()
        
        console.print("Starting Simple Ethereum Sync Monitor...", style="bold green")
        console.print("This version avoids complex layouts to prevent display issues", style="bold cyan")
        
        while True:
            try:
                # Clear screen manually
                os.system('clear' if os.name == 'posix' else 'cls')
                
                # Get current data
                geth_block = self.get_geth_block_number()
                lighthouse_slot = self.get_lighthouse_head_slot()
                self.update_historical_data(geth_block, lighthouse_slot)
                
                # Create progress bars
                progress = Progress(
                    SpinnerColumn(),
                    TextColumn("[progress.description]{task.description}"),
                    BarColumn(),
                    TaskProgressColumn(),
                    TimeRemainingColumn(),
                    console=console
                )
                
                # Create panels
                geth_panel = self.create_geth_detailed_panel(progress)
                lighthouse_panel = self.create_lighthouse_detailed_panel(progress)
                system_panel = self.create_system_detailed_panel()
                network_panel = self.create_network_panel()
                summary_table = self.create_sync_summary_table()
                
                # Display everything
                console.print(f"\n[bold blue]Enhanced Ethereum Sync Monitor - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}[/bold blue]\n")
                
                # Use simple columns layout
                from rich.columns import Columns
                panels = [geth_panel, lighthouse_panel, system_panel, network_panel]
                columns = Columns(panels, equal=True, expand=True)
                
                console.print(columns)
                console.print("\n")
                console.print(summary_table)
                console.print("\n")
                console.print(progress)
                
                console.print(f"\n[dim]Press Ctrl+C to exit | Auto-refresh every {refresh_interval} seconds[/dim]")
                
                time.sleep(refresh_interval)
                
            except KeyboardInterrupt:
                console.print("\nMonitor stopped. Goodbye!")
                break
            except Exception as e:
                console.print(f"\nError: {e}", style="bold red")
                time.sleep(refresh_interval)


def main():
    parser = argparse.ArgumentParser(description="Enhanced Ethereum Sync Monitor with Rich UI")
    parser.add_argument("--geth-port", type=int, default=8545, help="Geth HTTP port")
    parser.add_argument("--lighthouse-port", type=int, default=5052, help="Lighthouse HTTP port")
    parser.add_argument("--geth-data", default="./geth-data", help="Geth data directory path")
    parser.add_argument("--lighthouse-data", default="./lighthouse-data", help="Lighthouse data directory path")
    parser.add_argument("--interval", type=int, default=3, help="Refresh interval in seconds")
    parser.add_argument("--simple", action="store_true", help="Use simple display mode to avoid black screen issues")
    
    args = parser.parse_args()
    
    monitor = EnhancedEthereumSyncMonitor(
        geth_port=args.geth_port,
        lighthouse_port=args.lighthouse_port,
        geth_data_path=args.geth_data,
        lighthouse_data_path=args.lighthouse_data
    )
    
    console = Console()
    
    if args.simple:
        console.print("Starting Simple Ethereum Sync Monitor...", style="bold green")
        console.print("Simple mode avoids complex layouts to prevent display issues", style="bold cyan")
    else:
        console.print("Starting Enhanced Ethereum Sync Monitor with Rich UI...", style="bold green")
        console.print("New Features: Real-time sync rates (10s/10m/10h) & Network bandwidth monitoring", style="bold cyan")
    
    console.print(f"Geth port: {args.geth_port}", style="blue")
    console.print(f"Lighthouse port: {args.lighthouse_port}", style="yellow")
    console.print(f"Geth data: {args.geth_data}", style="blue")
    console.print(f"Lighthouse data: {args.lighthouse_data}", style="yellow")
    console.print(f"Refresh interval: {args.interval} seconds", style="green")
    console.print()
    
    try:
        if args.simple:
            monitor.run_simple_monitor(refresh_interval=args.interval)
        else:
            monitor.run_monitor(refresh_interval=args.interval)
    except Exception as e:
        console.print(f"Fatal error: {e}", style="bold red")
        console.print("Try running with --simple flag to avoid display issues", style="yellow")
        sys.exit(1)

if __name__ == "__main__":
    main()
