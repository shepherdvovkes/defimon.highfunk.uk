#!/usr/bin/env python3
"""
Simple test script to verify server configuration
"""

import requests
import time

def test_server():
    """Test if the server is running on port 8000"""
    try:
        print("🔍 Testing server on port 8000...")
        response = requests.get('http://localhost:8000/api/data-files', timeout=5)
        if response.status_code == 200:
            print("✅ Server is running successfully!")
            print(f"📊 Response: {response.json()}")
            return True
        else:
            print(f"❌ Server responded with status code: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Server is not running on port 8000")
        return False
    except Exception as e:
        print(f"❌ Error testing server: {e}")
        return False

if __name__ == "__main__":
    test_server()
