#!/bin/bash

# Ethereum Sync Monitor Runner
# This script runs the monitor in the background and captures output

cd ~/defimon.highfunk.uk/infrastructure/geth-monitoring

# Activate virtual environment
source monitor-env/bin/activate

# Set terminal environment
export TERM=xterm

# Run the monitor with output to both log file and screen
echo "Starting Ethereum Sync Monitor..."
echo "Monitor will run in background. Check monitor.log for output."
echo "To view real-time output: tail -f monitor.log"

# Run monitor in background with output to log file
nohup python3 ethereum-sync-monitor.py \
    --geth-data ./geth-data \
    --lighthouse-data ./lighthouse-data \
    --interval 3 \
    --no-clear > monitor.log 2>&1 &

# Get the PID
MONITOR_PID=$!
echo "Monitor started with PID: $MONITOR_PID"
echo "To stop monitor: kill $MONITOR_PID"
echo "To view output: tail -f monitor.log"
echo "To check status: ps aux | grep $MONITOR_PID"
