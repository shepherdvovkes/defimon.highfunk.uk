# Enhanced Ethereum Sync Monitor

## Overview
The Enhanced Ethereum Sync Monitor is a comprehensive Python CLI application that provides real-time monitoring of both Geth (execution layer) and Lighthouse (consensus layer) Ethereum nodes with detailed synchronization information, progress bars, and system metrics.

## Features

### 🚀 **Enhanced Sync Information**
- **Current Block Display**: Shows exact block numbers for both nodes
- **Remaining Blocks**: Calculates and displays remaining blocks to sync
- **Progress Percentage**: Real-time sync progress with 2 decimal precision
- **ETA Calculation**: Estimates time to complete synchronization
- **Sync Status**: Detailed status for both execution and consensus layers

### 📊 **Rich UI Components**
- **Progress Bars**: Visual progress bars for both Geth and Lighthouse
- **Live Updates**: Non-redrawing interface that only updates numbers
- **Color-coded Panels**: Blue for Geth, Yellow for Lighthouse, Green for System
- **Comprehensive Tables**: Summary table with overall sync status

### 🔍 **Detailed Metrics**

#### Geth (Execution Layer)
- Current Block Number
- Target Block Number  
- Remaining Blocks Count
- Sync Progress Percentage
- Estimated Time to Complete
- Connected Peer Count
- Data Directory Size

#### Lighthouse (Consensus Layer)
- Current Slot Number
- Sync Distance (slots behind)
- Sync Progress Percentage
- Syncing Status (Yes/No)
- Optimistic Status
- Execution Layer Connection Status
- Data Directory Size

#### System Information
- Total Disk Space
- Used Disk Space
- Free Disk Space
- Memory Usage (used/total + percentage)
- CPU Usage Percentage
- Network I/O Statistics

### 📈 **Real-time Monitoring**
- **Auto-refresh**: Configurable refresh interval (default: 3 seconds)
- **Live Updates**: Continuous monitoring without manual refresh
- **Error Handling**: Graceful error handling with informative messages
- **Session Management**: Runs in screen sessions for persistent monitoring

## Installation & Setup

### Prerequisites
- Python 3.7+
- Virtual environment with required packages
- Access to Geth and Lighthouse nodes

### Dependencies
```bash
requests>=2.25.1
psutil>=5.8.0
rich>=13.0.0
```

### Setup
1. **Copy the monitor to your server:**
   ```bash
   scp ethereum-sync-monitor-enhanced.py your-server:~/path/to/monitoring/
   ```

2. **Ensure virtual environment is activated:**
   ```bash
   source monitor-env/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## Usage

### Command Line Options
```bash
python3 ethereum-sync-monitor-enhanced.py [OPTIONS]

Options:
  --geth-port GETH_PORT           Geth HTTP port (default: 8545)
  --lighthouse-port LIGHTHOUSE_PORT  Lighthouse HTTP port (default: 5052)
  --geth-data GETH_DATA           Geth data directory path (default: ./geth-data)
  --lighthouse-data LIGHTHOUSE_DATA  Lighthouse data directory path (default: ./lighthouse-data)
  --interval INTERVAL             Refresh interval in seconds (default: 3)
  -h, --help                      Show help message
```

### Example Usage
```bash
# Basic usage with default settings
python3 ethereum-sync-monitor-enhanced.py

# Custom ports and data paths
python3 ethereum-sync-monitor-enhanced.py \
  --geth-port 8545 \
  --lighthouse-port 5052 \
  --geth-data /path/to/geth-data \
  --lighthouse-data /path/to/lighthouse-data \
  --interval 5
```

## Screen Session Management

### Control Script
Use the provided control script for easy management:

```bash
# Start the monitor
./enhanced-monitor-controls.sh start

# View the monitor
./enhanced-monitor-controls.sh view

# Check status
./enhanced-monitor-controls.sh status

# Stop the monitor
./enhanced-monitor-controls.sh stop

# Restart the monitor
./enhanced-monitor-controls.sh restart
```

### Manual Screen Commands
```bash
# List screen sessions
screen -list

# Attach to monitor session
screen -r ethereum-monitor-enhanced

# Detach from session (keep running)
# Press Ctrl+A, then D

# Stop session
screen -S ethereum-monitor-enhanced -X quit
```

## Sample Output

The monitor displays a comprehensive interface with:

```
╭─────────────────────────────────────────────────────────────────────╮
│ Enhanced Ethereum Sync Monitor - 2025-08-17 05:13:50              │
╰─────────────────────────────────────────────────────────────────────╯

╭──── GETH (Execution Layer) ────╮      ╭──────────── SYSTEM INFO ────╮
│ Current Block: 771,308         │      │ Total Disk: 500.0 GB        │
│ Target Block: 23,157,623       │      │ Used: 45.2 GB               │
│ Remaining: 22,386,315 blocks   │      │ Free: 454.8 GB              │
│ Progress: 3.33%                │      │ Memory: 8.1 GB / 16.0 GB   │
│ ETA: 6218h 25m                 │      │ CPU Usage: 12.3%            │
│ Connected Peers: 50            │      │ Network: 2.1 GB sent/recv   │
│ Data Size: 22.8 GB             │      ╰─────────────────────────────╯
╰─────────────────────────────────╯

╭─ LIGHTHOUSE (Consensus Layer) ─╮      ╭─ Ethereum Node Sync Summary ─╮
│ Current Slot: 12,381,055       │      │ Metric │ Geth │ Lighthouse │
│ Sync Distance: 1 slots         │      │ Current│ 771K │ 12.3M     │
│ Progress: 100.00%              │      │ Progress│ 3.3% │ Synced    │
│ Syncing: No                    │      │ Peers  │ 50   │ -         │
│ Optimistic: Yes                │      ╰─────────────────────────────╯
│ EL Connected: Yes              │
│ Data Size: 5.6 GB              │
╰─────────────────────────────────╯

⠋ Geth Sync       ━                                          3% -:--:--
⠋ Lighthouse Sync ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸ 100% -:--:--
```

## Error Handling

The monitor includes comprehensive error handling for:
- Network connectivity issues
- API endpoint failures
- Invalid data responses
- System resource access problems
- File system errors

All errors are displayed with informative messages and the monitor continues running.

## Performance Considerations

- **Memory Usage**: Minimal memory footprint (~50-100MB)
- **CPU Usage**: Low CPU usage, primarily during refresh cycles
- **Network**: Minimal network overhead for API calls
- **Disk I/O**: Only reads data directory sizes, no writing

## Troubleshooting

### Common Issues

1. **"System info error: too many values to unpack"**
   - Fixed in latest version
   - Related to psutil disk_usage function

2. **Monitor not displaying Rich UI**
   - Ensure running in attached screen session
   - Check terminal type (TERM=xterm)
   - Verify Rich library installation

3. **Connection refused errors**
   - Verify Geth and Lighthouse ports are correct
   - Check if nodes are running and accessible
   - Confirm firewall settings

### Debug Mode
For troubleshooting, run with verbose output:
```bash
python3 -u ethereum-sync-monitor-enhanced.py --interval 1
```

## Future Enhancements

- **Web Dashboard**: HTML/WebSocket interface
- **Alerting**: Email/Slack notifications for sync issues
- **Historical Data**: Sync progress tracking over time
- **Metrics Export**: Prometheus/InfluxDB integration
- **Mobile App**: Flutter-based mobile monitoring

## Contributing

To contribute to the enhanced monitor:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is part of the Defimon infrastructure monitoring suite.

---

**Quick Start:**
```bash
# Copy files to server
scp ethereum-sync-monitor-enhanced.py your-server:~/monitoring/
scp enhanced-monitor-controls.sh your-server:~/monitoring/

# Start monitoring
./enhanced-monitor-controls.sh start

# View monitor
./enhanced-monitor-controls.sh view
```
