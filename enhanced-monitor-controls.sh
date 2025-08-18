#!/bin/bash

# Enhanced Ethereum Monitor Controls
# This script provides easy control over the enhanced monitor

MONITOR_SESSION="ethereum-monitor-enhanced"

case "$1" in
    "start")
        echo "Starting Enhanced Ethereum Monitor..."
        cd ~/defimon.highfunk.uk/infrastructure/geth-monitoring
        if screen -list | grep -q "$MONITOR_SESSION"; then
            echo "⚠️  Monitor session already exists!"
            echo "Attaching to existing session..."
            screen -r "$MONITOR_SESSION"
        else
            source monitor-env/bin/activate
            screen -S "$MONITOR_SESSION" -d -m bash -c 'source monitor-env/bin/activate && python3 ethereum-sync-monitor-enhanced.py --geth-data ./geth-data --lighthouse-data ./lighthouse-data --interval 3'
            echo "✅ Enhanced monitor started in screen session '$MONITOR_SESSION'"
            echo "To view: screen -r $MONITOR_SESSION"
        fi
        ;;
    "view"|"show"|"attach")
        echo "Attaching to Enhanced Ethereum Monitor..."
        if screen -list | grep -q "$MONITOR_SESSION"; then
            screen -r "$MONITOR_SESSION"
        else
            echo "❌ No monitor session found. Start it first with: $0 start"
        fi
        ;;
    "stop"|"kill")
        echo "Stopping Enhanced Ethereum Monitor..."
        if screen -list | grep -q "$MONITOR_SESSION"; then
            screen -S "$MONITOR_SESSION" -X quit
            echo "✅ Monitor session stopped"
        else
            echo "❌ No monitor session found"
        fi
        ;;
    "status")
        echo "Enhanced Ethereum Monitor Status:"
        if screen -list | grep -q "$MONITOR_SESSION"; then
            echo "✅ Running in screen session: $MONITOR_SESSION"
            screen -list | grep "$MONITOR_SESSION"
        else
            echo "❌ Not running"
        fi
        ;;
    "restart")
        echo "Restarting Enhanced Ethereum Monitor..."
        $0 stop
        sleep 2
        $0 start
        ;;
    "logs")
        echo "Recent monitor activity (if any):"
        if screen -list | grep -q "$MONITOR_SESSION"; then
            echo "Monitor is running. Use 'screen -r $MONITOR_SESSION' to view live output."
        else
            echo "Monitor is not running"
        fi
        ;;
    *)
        echo "Enhanced Ethereum Monitor Controls"
        echo "Usage: $0 {start|view|stop|status|restart|logs}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the enhanced monitor in a screen session"
        echo "  view     - Attach to and view the monitor (same as 'attach')"
        echo "  attach   - Attach to and view the monitor"
        echo "  stop     - Stop the monitor session"
        echo "  status   - Show monitor status"
        echo "  restart  - Restart the monitor"
        echo "  logs     - Show log information"
        echo ""
        echo "Enhanced Features:"
        echo "- Detailed sync progress with current blocks and remaining blocks"
        echo "- Progress bars for both Geth and Lighthouse"
        echo "- Comprehensive system information"
        echo "- Sync summary table with overall status"
        echo "- ETA calculations for sync completion"
        echo "- Real-time data size monitoring"
        echo ""
        echo "Quick start: $0 start"
        echo "Quick view:  $0 view"
        ;;
esac
