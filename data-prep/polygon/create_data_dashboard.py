#!/usr/bin/env python3
"""
Create a modern web dashboard for QuickNode data analysis
"""

import json
import os
from datetime import datetime
from pathlib import Path

def load_analysis_data():
    """Load the analysis data"""
    try:
        with open('quicknode_data_analysis.json', 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print("❌ quicknode_data_analysis.json not found")
        return None

def create_dashboard_html(data):
    """Create the dashboard HTML"""
    
    # Extract data
    stats = data['stats']
    sample_blocks = data['sample_blocks']
    sample_transactions = data['sample_transactions']
    sample_receipts = data['sample_receipts']
    
    # Calculate additional statistics
    total_transactions = sum(len(block.get('transactions', [])) for block in sample_blocks)
    successful_transactions = sum(1 for receipt in sample_receipts if receipt.get('status') == '0x1')
    failed_transactions = len(sample_receipts) - successful_transactions
    
    # Gas price in Gwei
    gas_price_gwei = stats['current_gas_price'] / 1e9 if stats['current_gas_price'] else 0
    
    # Create charts data
    block_numbers = [int(block['number'], 16) if isinstance(block['number'], str) else block['number'] for block in sample_blocks]
    transaction_counts = [len(block.get('transactions', [])) for block in sample_blocks]
    gas_used = [int(block['gasUsed'], 16) if isinstance(block['gasUsed'], str) else block['gasUsed'] for block in sample_blocks]
    
    # Transaction status data
    status_data = {
        'Successful': successful_transactions,
        'Failed': failed_transactions
    }
    
    html = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Polygon Network Data Dashboard - Last Month</title>
    <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.js"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .gradient-bg {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }}
        .card-hover {{
            transition: transform 0.2s ease-in-out;
        }}
        .card-hover:hover {{
            transform: translateY(-2px);
        }}
        .stat-card {{
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }}
        .network-card {{
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }}
        .transaction-card {{
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
        }}
    </style>
</head>
<body class="bg-gray-50">
    <!-- Header -->
    <header class="gradient-bg text-white shadow-lg">
        <div class="container mx-auto px-6 py-8">
            <div class="flex items-center justify-between">
                <div>
                    <h1 class="text-4xl font-bold mb-2">
                        <i class="fas fa-chart-line mr-3"></i>
                        Polygon Network Dashboard
                    </h1>
                    <p class="text-xl opacity-90">QuickNode Data Analysis - Last Month</p>
                </div>
                <div class="text-right">
                    <div class="text-2xl font-bold">{stats['latest_block']:,}</div>
                    <div class="text-sm opacity-75">Latest Block</div>
                </div>
            </div>
        </div>
    </header>

    <!-- Main Content -->
    <main class="container mx-auto px-6 py-8">
        <!-- Network Statistics -->
        <section class="mb-8">
            <h2 class="text-3xl font-bold text-gray-800 mb-6">
                <i class="fas fa-network-wired mr-3 text-blue-600"></i>
                Network Statistics
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div class="stat-card rounded-lg p-6 text-white shadow-lg card-hover">
                    <div class="flex items-center">
                        <i class="fas fa-cube text-3xl mr-4"></i>
                        <div>
                            <div class="text-2xl font-bold">{stats['blocks_in_month']:,}</div>
                            <div class="text-sm opacity-90">Blocks in Month</div>
                        </div>
                    </div>
                </div>
                
                <div class="network-card rounded-lg p-6 text-white shadow-lg card-hover">
                    <div class="flex items-center">
                        <i class="fas fa-gas-pump text-3xl mr-4"></i>
                        <div>
                            <div class="text-2xl font-bold">{gas_price_gwei:.2f}</div>
                            <div class="text-sm opacity-90">Gas Price (Gwei)</div>
                        </div>
                    </div>
                </div>
                
                <div class="transaction-card rounded-lg p-6 text-white shadow-lg card-hover">
                    <div class="flex items-center">
                        <i class="fas fa-exchange-alt text-3xl mr-4"></i>
                        <div>
                            <div class="text-2xl font-bold">{total_transactions:,}</div>
                            <div class="text-sm opacity-90">Sample Transactions</div>
                        </div>
                    </div>
                </div>
                
                <div class="bg-gradient-to-r from-purple-500 to-pink-500 rounded-lg p-6 text-white shadow-lg card-hover">
                    <div class="flex items-center">
                        <i class="fas fa-percentage text-3xl mr-4"></i>
                        <div>
                            <div class="text-2xl font-bold">{successful_transactions/(successful_transactions+failed_transactions)*100:.1f}%</div>
                            <div class="text-sm opacity-90">Success Rate</div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Charts Section -->
        <section class="mb-8">
            <h2 class="text-3xl font-bold text-gray-800 mb-6">
                <i class="fas fa-chart-bar mr-3 text-green-600"></i>
                Network Analytics
            </h2>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <!-- Transactions per Block -->
                <div class="bg-white rounded-lg shadow-lg p-6">
                    <h3 class="text-xl font-semibold text-gray-800 mb-4">Transactions per Block</h3>
                    <canvas id="transactionsChart" width="400" height="200"></canvas>
                </div>
                
                <!-- Gas Usage -->
                <div class="bg-white rounded-lg shadow-lg p-6">
                    <h3 class="text-xl font-semibold text-gray-800 mb-4">Gas Usage per Block</h3>
                    <canvas id="gasChart" width="400" height="200"></canvas>
                </div>
                
                <!-- Transaction Status -->
                <div class="bg-white rounded-lg shadow-lg p-6">
                    <h3 class="text-xl font-semibold text-gray-800 mb-4">Transaction Status</h3>
                    <canvas id="statusChart" width="400" height="200"></canvas>
                </div>
                
                <!-- Block Timeline -->
                <div class="bg-white rounded-lg shadow-lg p-6">
                    <h3 class="text-xl font-semibold text-gray-800 mb-4">Block Timeline</h3>
                    <canvas id="timelineChart" width="400" height="200"></canvas>
                </div>
            </div>
        </section>

        <!-- Sample Data Tables -->
        <section class="mb-8">
            <h2 class="text-3xl font-bold text-gray-800 mb-6">
                <i class="fas fa-table mr-3 text-indigo-600"></i>
                Sample Data
            </h2>
            
            <!-- Blocks Table -->
            <div class="bg-white rounded-lg shadow-lg p-6 mb-6">
                <h3 class="text-xl font-semibold text-gray-800 mb-4">Sample Blocks</h3>
                <div class="overflow-x-auto">
                    <table class="min-w-full table-auto">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Block</th>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Hash</th>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Transactions</th>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Gas Used</th>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Timestamp</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            {''.join([f'''
                            <tr class="hover:bg-gray-50">
                                <td class="px-4 py-2 text-sm text-gray-900">{int(block['number'], 16) if isinstance(block['number'], str) else block['number']:,}</td>
                                <td class="px-4 py-2 text-sm text-gray-500 font-mono">{block['hash'][:20]}...</td>
                                <td class="px-4 py-2 text-sm text-gray-900">{len(block.get('transactions', []))}</td>
                                <td class="px-4 py-2 text-sm text-gray-900">{int(block['gasUsed'], 16) if isinstance(block['gasUsed'], str) else block['gasUsed']:,}</td>
                                <td class="px-4 py-2 text-sm text-gray-900">{datetime.fromtimestamp(int(block['timestamp'], 16) if isinstance(block['timestamp'], str) else block['timestamp']).strftime('%Y-%m-%d %H:%M:%S')}</td>
                            </tr>
                            ''' for block in sample_blocks[:5]])}
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- Transactions Table -->
            <div class="bg-white rounded-lg shadow-lg p-6">
                <h3 class="text-xl font-semibold text-gray-800 mb-4">Sample Transactions</h3>
                <div class="overflow-x-auto">
                    <table class="min-w-full table-auto">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Hash</th>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">From</th>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">To</th>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Value</th>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            {''.join([f'''
                            <tr class="hover:bg-gray-50">
                                <td class="px-4 py-2 text-sm text-gray-500 font-mono">{tx['hash'][:20]}...</td>
                                <td class="px-4 py-2 text-sm text-gray-500 font-mono">{tx['from'][:20]}...</td>
                                <td class="px-4 py-2 text-sm text-gray-500 font-mono">{tx.get('to', 'N/A')[:20] if tx.get('to') else 'N/A'}...</td>
                                <td class="px-4 py-2 text-sm text-gray-900">{int(tx['value'], 16) / 1e18 if isinstance(tx['value'], str) else tx['value'] / 1e18:.6f} MATIC</td>
                                <td class="px-4 py-2 text-sm">
                                    <span class="px-2 py-1 text-xs font-semibold rounded-full {'bg-green-100 text-green-800' if any(r.get('transactionHash') == tx['hash'] and r.get('status') == '0x1' for r in sample_receipts) else 'bg-red-100 text-red-800'}">
                                        {'Success' if any(r.get('transactionHash') == tx['hash'] and r.get('status') == '0x1' for r in sample_receipts) else 'Failed'}
                                    </span>
                                </td>
                            </tr>
                            ''' for tx in sample_transactions[:10]])}
                        </tbody>
                    </table>
                </div>
            </div>
        </section>

        <!-- Footer -->
        <footer class="text-center py-8 text-gray-600">
            <p>Data from QuickNode API • Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            <p class="text-sm mt-2">Analysis period: Last 30 days • Sample size: {len(sample_blocks)} blocks, {len(sample_transactions)} transactions</p>
        </footer>
    </main>

    <script>
        // Charts configuration
        const blockNumbers = {block_numbers};
        const transactionCounts = {transaction_counts};
        const gasUsed = {gas_used};
        const statusData = {status_data};
        
        // Transactions per Block Chart
        new Chart(document.getElementById('transactionsChart'), {{
            type: 'line',
            data: {{
                labels: blockNumbers.map(b => b.toLocaleString()),
                datasets: [{{
                    label: 'Transactions',
                    data: transactionCounts,
                    borderColor: 'rgb(59, 130, 246)',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    tension: 0.1
                }}]
            }},
            options: {{
                responsive: true,
                plugins: {{
                    legend: {{
                        display: false
                    }}
                }},
                scales: {{
                    y: {{
                        beginAtZero: true
                    }}
                }}
            }}
        }});
        
        // Gas Usage Chart
        new Chart(document.getElementById('gasChart'), {{
            type: 'bar',
            data: {{
                labels: blockNumbers.map(b => b.toLocaleString()),
                datasets: [{{
                    label: 'Gas Used',
                    data: gasUsed,
                    backgroundColor: 'rgba(34, 197, 94, 0.8)',
                    borderColor: 'rgb(34, 197, 94)',
                    borderWidth: 1
                }}]
            }},
            options: {{
                responsive: true,
                plugins: {{
                    legend: {{
                        display: false
                    }}
                }},
                scales: {{
                    y: {{
                        beginAtZero: true
                    }}
                }}
            }}
        }});
        
        // Transaction Status Chart
        new Chart(document.getElementById('statusChart'), {{
            type: 'doughnut',
            data: {{
                labels: Object.keys(statusData),
                datasets: [{{
                    data: Object.values(statusData),
                    backgroundColor: [
                        'rgba(34, 197, 94, 0.8)',
                        'rgba(239, 68, 68, 0.8)'
                    ],
                    borderColor: [
                        'rgb(34, 197, 94)',
                        'rgb(239, 68, 68)'
                    ],
                    borderWidth: 2
                }}]
            }},
            options: {{
                responsive: true,
                plugins: {{
                    legend: {{
                        position: 'bottom'
                    }}
                }}
            }}
        }});
        
        // Block Timeline Chart
        new Chart(document.getElementById('timelineChart'), {{
            type: 'line',
            data: {{
                labels: blockNumbers.map(b => b.toLocaleString()),
                datasets: [{{
                    label: 'Block Number',
                    data: blockNumbers,
                    borderColor: 'rgb(168, 85, 247)',
                    backgroundColor: 'rgba(168, 85, 247, 0.1)',
                    tension: 0.1,
                    pointRadius: 4
                }}]
            }},
            options: {{
                responsive: true,
                plugins: {{
                    legend: {{
                        display: false
                    }}
                }},
                scales: {{
                    y: {{
                        beginAtZero: false
                    }}
                }}
            }}
        }});
    </script>
</body>
</html>
"""
    
    return html

def main():
    """Main function"""
    print("🚀 Creating QuickNode Data Dashboard...")
    
    # Load analysis data
    data = load_analysis_data()
    if not data:
        print("❌ No analysis data found")
        return
    
    # Create dashboard HTML
    html = create_dashboard_html(data)
    
    # Save dashboard
    with open('quicknode_dashboard.html', 'w', encoding='utf-8') as f:
        f.write(html)
    
    print("✅ Dashboard created: quicknode_dashboard.html")
    print("📊 Features:")
    print("  • Network statistics with beautiful cards")
    print("  • Interactive charts (transactions, gas usage, status)")
    print("  • Sample data tables")
    print("  • Responsive design")
    print("  • Real-time data visualization")
    
    print("\n🌐 To view the dashboard:")
    print("1. Open quicknode_dashboard.html in your browser")
    print("2. Or run: python3 -m http.server 8000")
    print("3. Then visit: http://localhost:8000/quicknode_dashboard.html")

if __name__ == "__main__":
    main()
