#!/bin/bash

# Ethereum Monitor Tmux Control Script
# This script helps you manage the ethereum monitor running in tmux

echo "Ethereum Monitor Tmux Controls"
echo "=============================="
echo ""

# Check if session exists
if tmux has-session -t ethereum-monitor 2>/dev/null; then
    echo "✅ Monitor session is running"
    echo ""
    echo "Available commands:"
    echo "  View monitor:     tmux attach-session -t ethereum-monitor"
    echo "  Detach (keep running): Press Ctrl+B, then D"
    echo "  Stop monitor:     tmux kill-session -t ethereum-monitor"
    echo "  List sessions:    tmux list-sessions"
    echo "  Check status:     ps aux | grep ethereum-sync-monitor-rich"
    echo ""
    echo "Quick start:"
    echo "  tmux attach-session -t ethereum-monitor"
    echo ""
    echo "To exit monitor completely:"
    echo "  1. Attach to session: tmux attach-session -t ethereum-monitor"
    echo "  2. Press Ctrl+C to stop the monitor"
    echo "  3. Type 'exit' to close the tmux session"
else
    echo "❌ Monitor session is not running"
    echo ""
    echo "To start the monitor:"
    echo "  cd ~/defimon.highfunk.uk/infrastructure/geth-monitoring"
    echo "  tmux new-session -d -s ethereum-monitor 'source monitor-env/bin/activate && python3 ethereum-sync-monitor-rich.py --geth-data ./geth-data --lighthouse-data ./lighthouse-data --interval 3'"
    echo ""
    echo "Or use the run script:"
    echo "  ./run-monitor-rich.sh"
fi
