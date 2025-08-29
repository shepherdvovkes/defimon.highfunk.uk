#!/usr/bin/env python3
"""
DEFIMON Crab Data Collector via SSH
Collects data from the unified data server running on crab.local via SSH
"""

import subprocess
import json
import sqlite3
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('crab_data_collector_ssh.log'),
        logging.StreamHandler()
    ]
)

class CrabDataCollectorSSH:
    def __init__(self):
        # Initialize SQLite database
        self.init_database()
    
    def init_database(self):
        """Initialize SQLite database for storing collected data"""
        self.conn = sqlite3.connect('crab_data_ssh.db')
        self.cursor = self.conn.cursor()
        
        # Create tables
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS network_stats (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                network TEXT NOT NULL,
                total_blocks INTEGER,
                total_transactions INTEGER,
                total_volume TEXT,
                avg_gas_price TEXT,
                last_block_number INTEGER,
                last_block_timestamp TEXT,
                collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS blocks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                network TEXT NOT NULL,
                block_number INTEGER,
                block_hash TEXT,
                timestamp TEXT,
                transaction_count INTEGER,
                gas_used TEXT,
                gas_limit TEXT,
                miner TEXT,
                collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                network TEXT NOT NULL,
                tx_hash TEXT,
                block_number INTEGER,
                from_address TEXT,
                to_address TEXT,
                value TEXT,
                gas_price TEXT,
                gas_used TEXT,
                timestamp TEXT,
                collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS prices (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                asset TEXT NOT NULL,
                price_usd TEXT,
                volume_24h_usd TEXT,
                market_cap_usd TEXT,
                price_change_24h_percent TEXT,
                last_updated TEXT,
                collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS protocols (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                network TEXT,
                tvl TEXT,
                volume_24h TEXT,
                users_24h INTEGER,
                last_updated TEXT,
                collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        self.conn.commit()
        logging.info("Database initialized successfully")
    
    def ssh_curl(self, endpoint):
        """Execute curl command on crab server via SSH"""
        try:
            cmd = f'ssh crab.local "curl -s http://localhost:8002{endpoint}"'
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                return json.loads(result.stdout)
            else:
                logging.error(f"SSH curl failed for {endpoint}: {result.stderr}")
                return None
        except Exception as e:
            logging.error(f"SSH curl error for {endpoint}: {e}")
            return None
    
    def check_server_health(self):
        """Check if the server is running and healthy"""
        data = self.ssh_curl("/health")
        if data:
            logging.info(f"Server health: {data}")
            return True
        else:
            logging.error("Server health check failed")
            return False
    
    def collect_networks(self):
        """Collect available networks"""
        data = self.ssh_curl("/api/v1/networks")
        if data:
            networks = data.get('networks', [])
            logging.info(f"Available networks: {networks}")
            return networks
        else:
            logging.error("Failed to get networks")
            return []
    
    def collect_network_stats(self, network):
        """Collect stats for a specific network"""
        data = self.ssh_curl(f"/api/v1/networks/{network}/stats")
        if data:
            stats = data.get('stats', {})
            
            # Store in database
            self.cursor.execute('''
                INSERT INTO network_stats 
                (network, total_blocks, total_transactions, total_volume, avg_gas_price, 
                 last_block_number, last_block_timestamp)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                network,
                stats.get('total_blocks', 0),
                stats.get('total_transactions', 0),
                stats.get('total_volume', '0'),
                stats.get('avg_gas_price', '0'),
                stats.get('last_block_number', 0),
                stats.get('last_block_timestamp', ''),
            ))
            self.conn.commit()
            
            logging.info(f"Collected stats for {network}: {stats}")
            return stats
        else:
            logging.error(f"Failed to get stats for {network}")
            return None
    
    def collect_blocks(self, network, limit=10):
        """Collect recent blocks for a network"""
        data = self.ssh_curl(f"/api/v1/networks/{network}/blocks?limit={limit}")
        if data:
            blocks = data.get('blocks', [])
            
            for block in blocks:
                self.cursor.execute('''
                    INSERT INTO blocks 
                    (network, block_number, block_hash, timestamp, transaction_count, 
                     gas_used, gas_limit, miner)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    network,
                    block.get('number', 0),
                    block.get('hash', ''),
                    block.get('timestamp', ''),
                    block.get('transaction_count', 0),
                    block.get('gas_used', ''),
                    block.get('gas_limit', ''),
                    block.get('miner', ''),
                ))
            
            self.conn.commit()
            logging.info(f"Collected {len(blocks)} blocks for {network}")
            return blocks
        else:
            logging.error(f"Failed to get blocks for {network}")
            return []
    
    def collect_transactions(self, network, limit=10):
        """Collect recent transactions for a network"""
        data = self.ssh_curl(f"/api/v1/networks/{network}/transactions?limit={limit}")
        if data:
            transactions = data.get('transactions', [])
            
            for tx in transactions:
                self.cursor.execute('''
                    INSERT INTO transactions 
                    (network, tx_hash, block_number, from_address, to_address, 
                     value, gas_price, gas_used, timestamp)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    network,
                    tx.get('hash', ''),
                    tx.get('block_number', 0),
                    tx.get('from_address', ''),
                    tx.get('to_address', ''),
                    tx.get('value', ''),
                    tx.get('gas_price', ''),
                    tx.get('gas_used', ''),
                    tx.get('timestamp', ''),
                ))
            
            self.conn.commit()
            logging.info(f"Collected {len(transactions)} transactions for {network}")
            return transactions
        else:
            logging.error(f"Failed to get transactions for {network}")
            return []
    
    def collect_prices(self):
        """Collect price data"""
        data = self.ssh_curl("/api/v1/prices")
        if data:
            prices = data.get('prices', [])
            
            for price in prices:
                self.cursor.execute('''
                    INSERT INTO prices 
                    (asset, price_usd, volume_24h_usd, market_cap_usd, 
                     price_change_24h_percent, last_updated)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (
                    price.get('asset', ''),
                    price.get('price_usd', ''),
                    price.get('volume_24h_usd', ''),
                    price.get('market_cap_usd', ''),
                    price.get('price_change_24h_percent', ''),
                    price.get('last_updated', ''),
                ))
            
            self.conn.commit()
            logging.info(f"Collected {len(prices)} price records")
            return prices
        else:
            logging.error("Failed to get prices")
            return []
    
    def collect_protocols(self):
        """Collect protocol data"""
        data = self.ssh_curl("/api/v1/protocols")
        if data:
            protocols = data.get('protocols', [])
            
            for protocol in protocols:
                self.cursor.execute('''
                    INSERT INTO protocols 
                    (name, network, tvl, volume_24h, users_24h, last_updated)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (
                    protocol.get('name', ''),
                    protocol.get('network', ''),
                    protocol.get('tvl', ''),
                    protocol.get('volume_24h', ''),
                    protocol.get('users_24h', 0),
                    protocol.get('last_updated', ''),
                ))
            
            self.conn.commit()
            logging.info(f"Collected {len(protocols)} protocol records")
            return protocols
        else:
            logging.error("Failed to get protocols")
            return []
    
    def collect_dashboard_data(self):
        """Collect dashboard summary data"""
        data = self.ssh_curl("/api/v1/dashboard")
        if data:
            dashboard = data.get('dashboard', {})
            logging.info(f"Dashboard data: {dashboard}")
            return dashboard
        else:
            logging.error("Failed to get dashboard data")
            return None
    
    def collect_all_data(self):
        """Collect all available data"""
        logging.info("Starting comprehensive data collection from crab server via SSH...")
        
        # Check server health
        if not self.check_server_health():
            logging.error("Server is not healthy, aborting collection")
            return False
        
        # Collect networks
        networks = self.collect_networks()
        
        # Collect data for each network
        for network in networks:
            logging.info(f"Collecting data for network: {network}")
            
            # Network stats
            self.collect_network_stats(network)
            
            # Recent blocks
            self.collect_blocks(network, limit=5)
            
            # Recent transactions
            self.collect_transactions(network, limit=5)
        
        # Collect global data
        self.collect_prices()
        self.collect_protocols()
        self.collect_dashboard_data()
        
        logging.info("Data collection completed successfully!")
        return True
    
    def get_collection_summary(self):
        """Get summary of collected data"""
        try:
            # Count records in each table
            tables = ['network_stats', 'blocks', 'transactions', 'prices', 'protocols']
            summary = {}
            
            for table in tables:
                self.cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = self.cursor.fetchone()[0]
                summary[table] = count
            
            logging.info(f"Collection summary: {summary}")
            return summary
        except Exception as e:
            logging.error(f"Error getting summary: {e}")
            return {}
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    """Main function to run the data collector"""
    collector = CrabDataCollectorSSH()
    
    try:
        # Collect all data
        success = collector.collect_all_data()
        
        if success:
            # Show summary
            summary = collector.get_collection_summary()
            print("\n" + "="*50)
            print("CRAB DATA COLLECTION SUMMARY (SSH)")
            print("="*50)
            for table, count in summary.items():
                print(f"{table}: {count} records")
            print("="*50)
        else:
            print("Data collection failed!")
            
    except KeyboardInterrupt:
        logging.info("Data collection interrupted by user")
    except Exception as e:
        logging.error(f"Unexpected error: {e}")
    finally:
        collector.close()

if __name__ == "__main__":
    main()
