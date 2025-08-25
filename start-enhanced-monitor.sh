#!/bin/bash

# Enhanced Ethereum Monitor Starter
# This script starts the enhanced monitor in a screen session

cd ~/defimon.highfunk.uk/infrastructure/geth-monitoring

echo "Starting Enhanced Ethereum Monitor with Rich UI..."
echo "This will open a new screen session with the enhanced monitor running."
echo ""

# Check if session already exists
if screen -list | grep -q "ethereum-monitor-enhanced"; then
    echo "⚠️  Enhanced monitor session already exists!"
    echo "Attaching to existing session..."
    screen -r ethereum-monitor-enhanced
    exit 0
fi

# Activate virtual environment and start enhanced monitor
echo "Creating new screen session for enhanced monitor..."
screen -S ethereum-monitor-enhanced -d -m bash -c 'source monitor-env/bin/activate && python3 ethereum-sync-monitor-enhanced.py --geth-data ./geth-data --lighthouse-data ./lighthouse-data --interval 3'

echo "✅ Enhanced monitor started in screen session 'ethereum-monitor-enhanced'"
echo ""
echo "To view the enhanced monitor:"
echo "  screen -r ethereum-monitor-enhanced"
echo ""
echo "To detach (keep running): Press Ctrl+A, then D"
echo "To stop: Press Ctrl+C in the monitor, then type 'exit'"
echo ""
echo "Enhanced Features:"
echo "- Detailed sync progress with current blocks and remaining blocks"
echo "- Progress bars for both Geth and Lighthouse"
echo "- Comprehensive system information"
echo "- Sync summary table with overall status"
echo "- ETA calculations for sync completion"
echo "- Real-time data size monitoring"
echo ""
echo "Starting monitor now..."

# Wait a moment for the monitor to start
sleep 2

# Attach to the session
screen -r ethereum-monitor-enhanced
