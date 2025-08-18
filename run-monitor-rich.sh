#!/bin/bash

# Ethereum Sync Monitor Rich Runner
# This script runs the Rich UI monitor in the background

cd ~/defimon.highfunk.uk/infrastructure/geth-monitoring

# Activate virtual environment
source monitor-env/bin/activate

# Set terminal environment
export TERM=xterm

# Install/upgrade Rich if needed
pip install --upgrade rich

echo "Starting Ethereum Sync Monitor with Rich UI..."
echo "Monitor will run in background. Check monitor-rich.log for output."
echo "To view real-time output: tail -f monitor-rich.log"

# Run monitor in background with output to log file
nohup python3 ethereum-sync-monitor-rich.py \
    --geth-data ./geth-data \
    --lighthouse-data ./lighthouse-data \
    --interval 3 > monitor-rich.log 2>&1 &

# Get the PID
MONITOR_PID=$!
echo "Rich Monitor started with PID: $MONITOR_PID"
echo "To stop monitor: kill $MONITOR_PID"
echo "To view output: tail -f monitor-rich.log"
echo "To check status: ps aux | grep $MONITOR_PID"
echo ""
echo "Features:"
echo "- Progress bars for each node"
echo "- Live updating without screen redraw"
echo "- Beautiful Rich UI with colors and panels"
echo "- Real-time sync status monitoring"
