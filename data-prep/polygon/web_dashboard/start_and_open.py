#!/usr/bin/env python3
"""
Start the Flask server and open the browser automatically
"""

import subprocess
import time
import webbrowser
import threading
import sys
import os

def start_server():
    """Start the Flask server"""
    try:
        print("🚀 Starting Polygon Data Dashboard on port 8000...")
        subprocess.run([sys.executable, "app.py"], check=True)
    except KeyboardInterrupt:
        print("\n⏹️ Server stopped by user")
    except Exception as e:
        print(f"❌ Error starting server: {e}")

def open_browser():
    """Open the browser after a short delay"""
    time.sleep(3)  # Wait for server to start
    try:
        print("🌐 Opening browser to http://localhost:8000")
        webbrowser.open('http://localhost:8000')
    except Exception as e:
        print(f"❌ Error opening browser: {e}")

def main():
    """Main function"""
    print("🎉 Polygon Data Dashboard")
    print("=" * 40)
    
    # Start browser thread
    browser_thread = threading.Thread(target=open_browser)
    browser_thread.daemon = True
    browser_thread.start()
    
    # Start server
    start_server()

if __name__ == "__main__":
    main()
