#!/usr/bin/env python3
"""
Ethereum Sync Monitor - CLI Tool
Monitors geth and lighthouse sync status in real-time
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
import shutil

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
            return None
    
    def get_lighthouse_sync_status(self) -> Optional[Dict]:
        """Get lighthouse sync status via REST API"""
        try:
            response = self.session.get(f"http://localhost:{self.lighthouse_port}/eth/v1/node/syncing")
            if response.status_code == 200:
                return response.json().get("data", {})
            return None
        except Exception as e:
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
            return None
    
    def get_disk_usage(self, path: str) -> Tuple[int, int, int]:
        """Get disk usage for a path in bytes"""
        try:
            if os.path.exists(path):
                total, used, free = shutil.disk_usage(path)
                return total, used, free
        except Exception:
            pass
        return 0, 0, 0
    
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
    
    def calculate_sync_progress(self, current: int, target: int) -> float:
        """Calculate sync progress percentage"""
        if target == 0:
            return 0.0
        return min(100.0, (current / target) * 100)
    
    def display_status(self, clear_screen: bool = True):
        """Display current sync status"""
        if clear_screen:
            os.system('clear' if os.name == 'posix' else 'cls')
        
        print("=" * 80)
        print(f"🚀 Ethereum Sync Monitor - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 80)
        print()
        
        # Geth Status
        print("🔵 GETH (Execution Layer)")
        print("-" * 40)
        
        geth_sync = self.get_geth_sync_status()
        geth_block = self.get_geth_block_number()
        geth_peers = self.get_geth_peer_count()
        
        if geth_sync and isinstance(geth_sync, dict):
            current_block = int(geth_sync.get("currentBlock", "0x0"), 16)
            highest_block = int(geth_sync.get("highestBlock", "0x0"), 16)
            
            if highest_block > 0:
                remaining_blocks = highest_block - current_block
                progress = self.calculate_sync_progress(current_block, highest_block)
                
                print(f"📦 Current Block: {current_block:,}")
                print(f"🎯 Target Block: {highest_block:,}")
                print(f"⏳ Remaining: {remaining_blocks:,} blocks")
                print(f"📊 Progress: {progress:.2f}%")
            else:
                print("📦 Current Block: Starting sync...")
                print("🎯 Target Block: Unknown")
                print("⏳ Status: Initializing...")
        else:
            print("📦 Current Block: Unknown")
            print("🎯 Target Block: Unknown")
            print("⏳ Status: Not syncing or error")
        
        if geth_peers is not None:
            print(f"🌐 Connected Peers: {geth_peers}")
        else:
            print("🌐 Connected Peers: Unknown")
        
        # Geth Disk Usage
        geth_size = self.get_directory_size(self.geth_data_path)
        print(f"💾 Data Size: {self.format_bytes(geth_size)}")
        
        print()
        
        # Lighthouse Status
        print("🟡 LIGHTHOUSE (Consensus Layer)")
        print("-" * 40)
        
        lighthouse_sync = self.get_lighthouse_sync_status()
        lighthouse_head = self.get_lighthouse_head_slot()
        
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
            
            print(f"📦 Current Slot: {head_slot:,}")
            print(f"⏳ Sync Distance: {sync_distance:,} slots")
            print(f"🔄 Syncing: {'Yes' if is_syncing else 'No'}")
            print(f"🎯 Optimistic: {'Yes' if is_optimistic else 'No'}")
            print(f"🔗 EL Connected: {'No' if el_offline else 'Yes'}")
            
            if sync_distance > 0:
                # Rough estimate: 12 seconds per slot
                estimated_seconds = sync_distance * 12
                print(f"⏱️  Estimated Time: {self.format_time(estimated_seconds)}")
        else:
            print("📦 Current Slot: Unknown")
            print("⏳ Sync Distance: Unknown")
            print("🔄 Status: Error or not responding")
        
        # Lighthouse Disk Usage
        lighthouse_size = self.get_directory_size(self.lighthouse_data_path)
        print(f"💾 Data Size: {self.format_bytes(lighthouse_size)}")
        
        print()
        
        # System Info
        print("🖥️  SYSTEM INFO")
        print("-" * 40)
        
        try:
            # Get disk usage for the current directory
            total, used, free = self.get_disk_usage(".")
            print(f"💽 Total Disk: {self.format_bytes(total)}")
            print(f"💽 Used: {self.format_bytes(used)}")
            print(f"💽 Free: {self.format_bytes(free)}")
            
            # Get memory usage
            memory = psutil.virtual_memory()
            print(f"🧠 Memory Used: {self.format_bytes(memory.used)} / {self.format_bytes(memory.total)} ({memory.percent:.1f}%)")
            
            # Get CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            print(f"⚡ CPU Usage: {cpu_percent:.1f}%")
            
        except Exception as e:
            print(f"⚠️  System info error: {e}")
        
        print()
        print("=" * 80)
        print("Press Ctrl+C to exit | Auto-refresh every 5 seconds")
        print("=" * 80)

def main():
    parser = argparse.ArgumentParser(description="Ethereum Sync Monitor")
    parser.add_argument("--geth-port", type=int, default=8545, help="Geth HTTP port")
    parser.add_argument("--lighthouse-port", type=int, default=5052, help="Lighthouse HTTP port")
    parser.add_argument("--geth-data", default="./geth-data", help="Geth data directory path")
    parser.add_argument("--lighthouse-data", default="./lighthouse-data", help="Lighthouse data directory path")
    parser.add_argument("--interval", type=int, default=5, help="Refresh interval in seconds")
    parser.add_argument("--no-clear", action="store_true", help="Don't clear screen between updates")
    
    args = parser.parse_args()
    
    monitor = EthereumSyncMonitor(
        geth_port=args.geth_port,
        lighthouse_port=args.lighthouse_port,
        geth_data_path=args.geth_data,
        lighthouse_data_path=args.lighthouse_data
    )
    
    print("🚀 Starting Ethereum Sync Monitor...")
    print(f"📡 Geth port: {args.geth_port}")
    print(f"📡 Lighthouse port: {args.lighthouse_port}")
    print(f"📁 Geth data: {args.geth_data}")
    print(f"📁 Lighthouse data: {args.lighthouse_data}")
    print(f"⏱️  Refresh interval: {args.interval} seconds")
    print()
    
    try:
        while True:
            monitor.display_status(clear_screen=not args.no_clear)
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\n👋 Monitor stopped. Goodbye!")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
