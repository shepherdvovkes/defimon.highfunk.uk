#!/usr/bin/env python3
"""
Test script to verify Google Cloud connection and bot setup
"""

import os
import sys
from dotenv import load_dotenv

def test_environment():
    """Test if environment variables are properly set"""
    print("🔍 Testing environment configuration...")
    
    # Load environment variables
    load_dotenv()
    
    required_vars = ['TELEGRAM_BOT_TOKEN', 'GOOGLE_CLOUD_PROJECT_ID']
    missing_vars = []
    
    for var in required_vars:
        value = os.getenv(var)
        if not value or value.startswith('your_'):
            missing_vars.append(var)
            print(f"❌ {var}: Not set or using placeholder value")
        else:
            print(f"✅ {var}: Set")
    
    if missing_vars:
        print(f"\n❌ Missing required environment variables: {', '.join(missing_vars)}")
        print("Please configure your .env file before running the bot.")
        return False
    
    print("✅ Environment configuration test passed")
    return True

def test_imports():
    """Test if all required modules can be imported"""
    print("\n🔍 Testing module imports...")
    
    try:
        import telegram
        print("✅ python-telegram-bot imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import python-telegram-bot: {e}")
        return False
    
    try:
        from google.cloud import container_v1, billing_v1, resourcemanager_v3
        print("✅ Google Cloud modules imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import Google Cloud modules: {e}")
        return False
    
    try:
        from google.auth import default
        print("✅ Google Auth imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import Google Auth: {e}")
        return False
    
    try:
        from dotenv import load_dotenv
        print("✅ python-dotenv imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import python-dotenv: {e}")
        return False
    
    print("✅ All module imports test passed")
    return True

def test_gcloud_connection():
    """Test Google Cloud connection"""
    print("\n🔍 Testing Google Cloud connection...")
    
    try:
        from gcloud_client import GCloudClient
        
        # Test connection
        client = GCloudClient()
        if client.test_connection():
            print("✅ Google Cloud connection test passed")
            return True
        else:
            print("❌ Google Cloud connection test failed")
            return False
            
    except Exception as e:
        print(f"❌ Google Cloud connection test failed with error: {e}")
        return False

def test_bot_handlers():
    """Test bot handlers import"""
    print("\n🔍 Testing bot handlers...")
    
    try:
        from bot_handlers import BotHandlers
        print("✅ Bot handlers imported successfully")
        return True
    except Exception as e:
        print(f"❌ Failed to import bot handlers: {e}")
        return False

def main():
    """Main test function"""
    print("🚀 Google Cloud Monitor Telegram Bot - Setup Test")
    print("=" * 55)
    
    # Run all tests
    tests = [
        ("Environment Configuration", test_environment),
        ("Module Imports", test_imports),
        ("Google Cloud Connection", test_gcloud_connection),
        ("Bot Handlers", test_bot_handlers)
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} test failed with exception: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 55)
    print("📊 Test Results Summary")
    print("=" * 55)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} {test_name}")
        if result:
            passed += 1
    
    print(f"\nOverall: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! Your bot is ready to run.")
        print("Run 'python bot.py' to start the bot.")
    else:
        print(f"\n⚠️ {total - passed} test(s) failed. Please fix the issues before running the bot.")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
