#!/bin/bash

# Ethereum Monitor Screen Control Script
# This script helps you manage the ethereum monitor running in screen

echo "Ethereum Monitor Screen Controls"
echo "================================="
echo ""

# Check if screen session exists
if screen -list | grep -q "ethereum-monitor"; then
    echo "✅ Monitor session is running in screen"
    echo ""
    echo "Available commands:"
    echo "  View monitor:     screen -r ethereum-monitor"
    echo "  Detach (keep running): Press Ctrl+A, then D"
    echo "  Stop monitor:     screen -S ethereum-monitor -X quit"
    echo "  List sessions:    screen -list"
    echo "  Check status:     ps aux | grep ethereum-sync-monitor-rich"
    echo ""
    echo "Quick start:"
    echo "  screen -r ethereum-monitor"
    echo ""
    echo "To exit monitor completely:"
    echo "  1. Attach to session: screen -r ethereum-monitor"
    echo "  2. Press Ctrl+C to stop the monitor"
    echo "  3. Type 'exit' to close the screen session"
    echo ""
    echo "Current screen sessions:"
    screen -list
else
    echo "❌ Monitor session is not running"
    echo ""
    echo "To start the monitor:"
    echo "  ssh vovkes-server"
    echo "  cd defimon.highfunk.uk/infrastructure/geth-monitoring"
    echo "  screen -dmS ethereum-monitor bash -c 'source monitor-env/bin/activate && python3 ethereum-sync-monitor-rich.py --geth-data ./geth-data --lighthouse-data ./lighthouse-data --interval 3'"
fi
