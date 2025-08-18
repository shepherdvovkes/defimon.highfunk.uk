#!/usr/bin/env python3
"""
Ethereum Sync Monitor - Rich CLI Tool
Monitors geth and lighthouse sync status with live progress bars
"""

import json
import time
import requests
import psutil
import os
import sys
from datetime import datetime, timedelta
from typing import Dict, Optional, Tuple
import argparse
from rich.console import Console
from rich.layout import Layout
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn, TimeRemainingColumn
from rich.table import Table
from rich.text import Text
from rich.live import Live
from rich.columns import Columns

class EthereumSyncMonitor:
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
        except Exception:
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
        except Exception:
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
        except Exception:
            return None
    
    def get_lighthouse_sync_status(self) -> Optional[Dict]:
        """Get lighthouse sync status via REST API"""
        try:
            response = self.session.get(f"http://localhost:{self.lighthouse_port}/eth/v1/node/syncing")
            if response.status_code == 200:
                return response.json().get("data", {})
            return None
        except Exception:
            return None
    
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
    
    def create_geth_panel(self, progress: Progress) -> Panel:
        """Create geth status panel with progress bar"""
        geth_sync = self.get_geth_sync_status()
        geth_peers = self.get_geth_peer_count()
        geth_size = self.get_directory_size(self.geth_data_path)
        
        # Create progress bar for geth
        if geth_sync and isinstance(geth_sync, dict):
            current_block = int(geth_sync.get("currentBlock", "0x0"), 16)
            highest_block = int(geth_sync.get("highestBlock", "0x0"), 16)
            
            if highest_block > 0:
                # Update or create progress bar
                task_id = progress.add_task("Geth Sync", total=highest_block)
                progress.update(task_id, completed=current_block)
                
                remaining_blocks = highest_block - current_block
                progress_percent = (current_block / highest_block) * 100 if highest_block > 0 else 0
                
                content = f"""
Current Block: {current_block:,}
Target Block: {highest_block:,}
Remaining: {remaining_blocks:,} blocks
Progress: {progress_percent:.2f}%
Connected Peers: {geth_peers or 'Unknown'}
Data Size: {self.format_bytes(geth_size)}
                """.strip()
            else:
                content = f"""
Status: Initializing sync...
Current Block: Starting...
Connected Peers: {geth_peers or 'Unknown'}
Data Size: {self.format_bytes(geth_size)}
                """.strip()
        else:
            content = f"""
Status: Not syncing or error
Connected Peers: {geth_peers or 'Unknown'}
Data Size: {self.format_bytes(geth_size)}
                """.strip()
        
        return Panel(content, title="GETH (Execution Layer)", border_style="blue")
    
    def create_lighthouse_panel(self, progress: Progress) -> Panel:
        """Create lighthouse status panel with progress bar"""
        lighthouse_sync = self.get_lighthouse_sync_status()
        lighthouse_size = self.get_directory_size(self.lighthouse_data_path)
        
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
                content = f"""
Current Slot: {head_slot:,}
Sync Distance: {sync_distance:,} slots
Syncing: {'Yes' if is_syncing else 'No'}
Optimistic: {'Yes' if is_optimistic else 'No'}
EL Connected: {'No' if el_offline else 'Yes'}
Estimated Time: {self.format_time(estimated_seconds)}
Data Size: {self.format_bytes(lighthouse_size)}
                """.strip()
            else:
                content = f"""
Current Slot: {head_slot:,}
Sync Distance: 0 slots (Synced!)
Syncing: {'Yes' if is_syncing else 'No'}
Optimistic: {'Yes' if is_optimistic else 'No'}
EL Connected: {'No' if el_offline else 'Yes'}
Data Size: {self.format_bytes(lighthouse_size)}
                """.strip()
        else:
            content = f"""
Status: Error or not responding
Data Size: {self.format_bytes(lighthouse_size)}
                """.strip()
        
        return Panel(content, title="LIGHTHOUSE (Consensus Layer)", border_style="yellow")
    
    def create_system_panel(self) -> Panel:
        """Create system info panel"""
        try:
            # Get disk usage for the current directory
            total, used, free = psutil.disk_usage(".")
            
            # Get memory usage
            memory = psutil.virtual_memory()
            
            # Get CPU usage
            cpu_percent = psutil.cpu_percent(interval=0.1)
            
            content = f"""
Total Disk: {self.format_bytes(total)}
Used: {self.format_bytes(used)}
Free: {self.format_bytes(free)}
Memory Used: {self.format_bytes(memory.used)} / {self.format_bytes(memory.total)} ({memory.percent:.1f}%)
CPU Usage: {cpu_percent:.1f}%
            """.strip()
            
        except Exception as e:
            content = f"System info error: {e}"
        
        return Panel(content, title="SYSTEM INFO", border_style="green")
    
    def create_status_table(self) -> Table:
        """Create a status table with key metrics"""
        table = Table(title="Ethereum Node Status")
        table.add_column("Metric", style="cyan")
        table.add_column("Geth", style="blue")
        table.add_column("Lighthouse", style="yellow")
        table.add_column("System", style="green")
        
        # Geth metrics
        geth_sync = self.get_geth_sync_status()
        geth_peers = self.get_geth_peer_count()
        
        if geth_sync and isinstance(geth_sync, dict):
            current_block = int(geth_sync.get("currentBlock", "0x0"), 16)
            highest_block = int(geth_sync.get("highestBlock", "0x0"), 16)
            geth_status = f"Block {current_block:,}" if highest_block > 0 else "Initializing"
        else:
            geth_status = "Unknown"
        
        # Lighthouse metrics
        lighthouse_sync = self.get_lighthouse_sync_status()
        if lighthouse_sync:
            head_slot = lighthouse_sync.get("head_slot", 0)
            sync_distance = lighthouse_sync.get("sync_distance", 0)
            lighthouse_status = f"Slot {head_slot:,}" + (f" (+{sync_distance})" if sync_distance > 0 else " (Synced)")
        else:
            lighthouse_status = "Unknown"
        
        # System metrics
        try:
            memory = psutil.virtual_memory()
            cpu_percent = psutil.cpu_percent(interval=0.1)
            system_status = f"CPU: {cpu_percent:.1f}% | RAM: {memory.percent:.1f}%"
        except:
            system_status = "Unknown"
        
        table.add_row("Status", geth_status, lighthouse_status, system_status)
        table.add_row("Peers", str(geth_peers or "Unknown"), "-", "-")
        
        return table
    
    def run_monitor(self, refresh_interval: int = 3):
        """Run the monitor with live updates"""
        console = Console()
        
        with console.screen():
            while True:
                try:
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
                    
                    # Header with timestamp
                    header = Panel(
                        f"Ethereum Sync Monitor - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
                        style="bold blue"
                    )
                    
                    # Create panels
                    geth_panel = self.create_geth_panel(progress)
                    lighthouse_panel = self.create_lighthouse_panel(progress)
                    system_panel = self.create_system_panel()
                    status_table = self.create_status_table()
                    
                    # Layout panels
                    layout["header"].update(header)
                    layout["left"].update(Columns([geth_panel, lighthouse_panel]))
                    layout["right"].update(Columns([system_panel, status_table]))
                    
                    # Footer with controls
                    footer = Panel(
                        "Press Ctrl+C to exit | Auto-refresh every {} seconds".format(refresh_interval),
                        style="dim"
                    )
                    layout["footer"].update(footer)
                    
                    # Display with progress bars
                    console.clear()
                    console.print(layout)
                    console.print(progress)
                    
                    time.sleep(refresh_interval)
                    
                except KeyboardInterrupt:
                    console.print("\nMonitor stopped. Goodbye!")
                    break
                except Exception as e:
                    console.print(f"\nError: {e}")
                    time.sleep(refresh_interval)

def main():
    parser = argparse.ArgumentParser(description="Ethereum Sync Monitor with Rich UI")
    parser.add_argument("--geth-port", type=int, default=8545, help="Geth HTTP port")
    parser.add_argument("--lighthouse-port", type=int, default=5052, help="Lighthouse HTTP port")
    parser.add_argument("--geth-data", default="./geth-data", help="Geth data directory path")
    parser.add_argument("--lighthouse-data", default="./lighthouse-data", help="Lighthouse data directory path")
    parser.add_argument("--interval", type=int, default=3, help="Refresh interval in seconds")
    
    args = parser.parse_args()
    
    monitor = EthereumSyncMonitor(
        geth_port=args.geth_port,
        lighthouse_port=args.lighthouse_port,
        geth_data_path=args.geth_data,
        lighthouse_data_path=args.lighthouse_data
    )
    
    console = Console()
    console.print("Starting Ethereum Sync Monitor with Rich UI...", style="bold green")
    console.print(f"Geth port: {args.geth_port}", style="blue")
    console.print(f"Lighthouse port: {args.lighthouse_port}", style="yellow")
    console.print(f"Geth data: {args.geth_data}", style="blue")
    console.print(f"Lighthouse data: {args.lighthouse_data}", style="yellow")
    console.print(f"Refresh interval: {args.interval} seconds", style="green")
    console.print()
    
    try:
        monitor.run_monitor(refresh_interval=args.interval)
    except Exception as e:
        console.print(f"Fatal error: {e}", style="bold red")
        sys.exit(1)

if __name__ == "__main__":
    main()
