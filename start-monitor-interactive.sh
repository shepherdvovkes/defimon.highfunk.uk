#!/bin/bash

# Ethereum Monitor Interactive Starter
# This script starts the monitor in an interactive tmux session

cd ~/defimon.highfunk.uk/infrastructure/geth-monitoring

echo "Starting Ethereum Monitor with Rich UI..."
echo "This will open a new tmux session with the monitor running."
echo ""

# Check if session already exists
if tmux has-session -t ethereum-monitor 2>/dev/null; then
    echo "⚠️  Monitor session already exists!"
    echo "Attaching to existing session..."
    tmux attach-session -t ethereum-monitor
    exit 0
fi

# Activate virtual environment and start monitor
echo "Creating new tmux session..."
tmux new-session -s ethereum-monitor -d 'source monitor-env/bin/activate && python3 ethereum-sync-monitor-rich.py --geth-data ./geth-data --lighthouse-data ./lighthouse-data --interval 3'

echo "✅ Monitor started in tmux session 'ethereum-monitor'"
echo ""
echo "To view the monitor:"
echo "  tmux attach-session -t ethereum-monitor"
echo ""
echo "To detach (keep running): Press Ctrl+B, then D"
echo "To stop: Press Ctrl+C in the monitor, then type 'exit'"
echo ""
echo "Attaching to session now..."

# Wait a moment for the monitor to start
sleep 2

# Attach to the session
tmux attach-session -t ethereum-monitor
