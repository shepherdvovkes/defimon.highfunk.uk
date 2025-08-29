#!/usr/bin/env python3
"""
Verify Cloud SQL Proxy connection and check what's running on port 5432
"""

import os
import socket
import subprocess
import asyncio
import asyncpg
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def check_port_5432():
    """Check what's running on port 5432"""
    print("🔍 Checking what's running on port 5432...")
    
    try:
        # Try to connect to port 5432
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex(('localhost', 5432))
        sock.close()
        
        if result == 0:
            print("✅ Port 5432 is open and accepting connections")
            
            # Check what process is using port 5432
            try:
                result = subprocess.run(['lsof', '-i', ':5432'], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    print("📊 Processes using port 5432:")
                    print(result.stdout)
                else:
                    print("⚠️ Could not determine what's using port 5432")
            except Exception as e:
                print(f"⚠️ Error checking processes: {e}")
            
            return True
        else:
            print("❌ Port 5432 is not open")
            return False
            
    except Exception as e:
        print(f"❌ Error checking port 5432: {e}")
        return False

def check_cloud_sql_proxy():
    """Check Cloud SQL Proxy status"""
    print("\n🔍 Checking Cloud SQL Proxy status...")
    
    try:
        # Check if proxy is running
        result = subprocess.run(['ps', 'aux'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            if 'cloud_sql_proxy' in result.stdout:
                print("✅ Cloud SQL Proxy process is running")
                # Show proxy process details
                lines = result.stdout.split('\n')
                for line in lines:
                    if 'cloud_sql_proxy' in line:
                        print(f"📊 Process: {line.strip()}")
            else:
                print("❌ Cloud SQL Proxy process not found")
        else:
            print("⚠️ Could not check processes")
    except Exception as e:
        print(f"❌ Error checking Cloud SQL Proxy: {e}")

async def test_postgres_connection():
    """Test basic PostgreSQL connection"""
    print("\n🧪 Testing PostgreSQL connection...")
    
    try:
        # Try to connect without specifying user/database
        dsn = 'postgresql://localhost:5432'
        print(f"🔗 Trying: {dsn}")
        
        conn = await asyncpg.connect(dsn)
        result = await conn.fetchval('SELECT version()')
        print(f"✅ Connected successfully!")
        print(f"📄 PostgreSQL version: {result}")
        
        # Check current database
        db_name = await conn.fetchval('SELECT current_database()')
        print(f"📊 Current database: {db_name}")
        
        # Check current user
        user = await conn.fetchval('SELECT current_user')
        print(f"👤 Current user: {user}")
        
        # List all databases
        databases = await conn.fetch("SELECT datname FROM pg_database WHERE datistemplate = false")
        print(f"📊 Available databases: {[d['datname'] for d in databases]}")
        
        await conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False

async def test_specific_database():
    """Test connection to specific database"""
    print("\n🧪 Testing specific database connection...")
    
    database = os.getenv('GOOGLE_CLOUD_SQL_DATABASE_NAME', 'defi_analytics')
    
    try:
        # Try to connect to specific database
        dsn = f'postgresql://localhost:5432/{database}'
        print(f"🔗 Trying: {dsn}")
        
        conn = await asyncpg.connect(dsn)
        result = await conn.fetchval('SELECT version()')
        print(f"✅ Connected to {database} successfully!")
        print(f"📄 PostgreSQL version: {result}")
        
        # Check current user
        user = await conn.fetchval('SELECT current_user')
        print(f"👤 Current user: {user}")
        
        # List all users
        users = await conn.fetch("SELECT usename FROM pg_user")
        print(f"👥 Available users: {[u['usename'] for u in users]}")
        
        await conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Connection to {database} failed: {e}")
        return False

async def main():
    """Main function"""
    print("🚀 Cloud SQL Connection Verification")
    print("=" * 50)
    
    # Check port 5432
    port_open = check_port_5432()
    
    # Check Cloud SQL Proxy
    check_cloud_sql_proxy()
    
    if port_open:
        # Test basic connection
        basic_connection = await test_postgres_connection()
        
        if basic_connection:
            # Test specific database
            await test_specific_database()
        else:
            print("\n❌ Basic PostgreSQL connection failed")
            print("💡 This suggests:")
            print("1. Cloud SQL Proxy is not connecting to the right instance")
            print("2. The PostgreSQL instance is not running")
            print("3. Network/firewall issues")
    else:
        print("\n❌ Port 5432 is not open")
        print("💡 This suggests:")
        print("1. Cloud SQL Proxy is not running")
        print("2. Proxy is not configured correctly")
        print("3. Instance connection string is wrong")
    
    print("\n" + "=" * 50)
    print("📋 Summary:")
    print(f"  Port 5432: {'✅ Open' if port_open else '❌ Closed'}")
    print("  Next steps:")
    print("1. Check Google Cloud Console for instance status")
    print("2. Verify Cloud SQL Proxy configuration")
    print("3. Check instance connection string")

if __name__ == "__main__":
    asyncio.run(main())
