#!/usr/bin/env python3
"""
Test PostgreSQL database connection to Google Cloud SQL
"""

import os
import asyncio
import asyncpg
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

async def test_direct_connection():
    """Test direct connection to PostgreSQL"""
    print("🔗 Testing Direct PostgreSQL Connection...")
    
    # Get database credentials
    user = os.getenv('GOOGLE_CLOUD_SQL_USER', 'defimon_user')
    password = os.getenv('GOOGLE_CLOUD_SQL_PASSWORD', 'Zd8odJnKfXf0pFAkCoaH')
    database = os.getenv('GOOGLE_CLOUD_SQL_DATABASE_NAME', 'defi_analytics')
    instance = os.getenv('GOOGLE_CLOUD_SQL_INSTANCE_NAME', 'defimon-postgres-instance')
    project = os.getenv('GOOGLE_CLOUD_PROJECT_ID', 'defimon-ethereum-node')
    region = os.getenv('GOOGLE_CLOUD_REGION', 'us-central1')
    
    print(f"📊 Database Configuration:")
    print(f"  Instance: {instance}")
    print(f"  Database: {database}")
    print(f"  User: {user}")
    print(f"  Project: {project}")
    print(f"  Region: {region}")
    
    # Try different connection methods
    connection_methods = [
        {
            'name': 'Localhost (Cloud SQL Proxy)',
            'dsn': f'postgresql://{user}:{password}@localhost:5432/{database}'
        },
        {
            'name': 'Public IP (if configured)',
            'dsn': f'postgresql://{user}:{password}@34.42.123.45:5432/{database}'  # Example IP
        },
        {
            'name': 'Unix Socket (Cloud SQL)',
            'dsn': f'postgresql://{user}:{password}@/{database}?host=/cloudsql/{project}:{region}:{instance}'
        }
    ]
    
    for method in connection_methods:
        print(f"\n🧪 Testing {method['name']}...")
        try:
            conn = await asyncpg.connect(method['dsn'])
            
            # Test basic query
            result = await conn.fetchval('SELECT version()')
            print(f"✅ {method['name']}: Connected successfully!")
            print(f"📄 PostgreSQL version: {result}")
            
            # Test database stats
            db_size = await conn.fetchval("SELECT pg_size_pretty(pg_database_size(current_database()))")
            table_count = await conn.fetchval("SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public'")
            
            print(f"📊 Database size: {db_size}")
            print(f"📊 Tables: {table_count}")
            
            await conn.close()
            return True
            
        except Exception as e:
            print(f"❌ {method['name']}: {e}")
    
    return False

async def test_cloud_sql_proxy():
    """Test if Cloud SQL Proxy is available"""
    print("\n🔗 Testing Cloud SQL Proxy...")
    
    try:
        import subprocess
        result = subprocess.run(['cloud_sql_proxy', '--version'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print("✅ Cloud SQL Proxy is installed")
            print(f"📄 Version: {result.stdout.strip()}")
            return True
        else:
            print("❌ Cloud SQL Proxy is not installed or not working")
            return False
    except FileNotFoundError:
        print("❌ Cloud SQL Proxy is not installed")
        return False
    except Exception as e:
        print(f"❌ Error checking Cloud SQL Proxy: {e}")
        return False

async def setup_cloud_sql_proxy():
    """Setup Cloud SQL Proxy connection"""
    print("\n🔧 Setting up Cloud SQL Proxy...")
    
    project = os.getenv('GOOGLE_CLOUD_PROJECT_ID', 'defimon-ethereum-node')
    region = os.getenv('GOOGLE_CLOUD_REGION', 'us-central1')
    instance = os.getenv('GOOGLE_CLOUD_SQL_INSTANCE_NAME', 'defimon-postgres-instance')
    
    print(f"📊 Instance: {project}:{region}:{instance}")
    
    # Check if proxy is already running
    try:
        import subprocess
        result = subprocess.run(['lsof', '-i', ':5432'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print("✅ Cloud SQL Proxy is already running on port 5432")
            return True
    except Exception:
        pass
    
    print("⚠️ Cloud SQL Proxy not running. You may need to:")
    print("1. Install Cloud SQL Proxy: https://cloud.google.com/sql/docs/postgres/connect-admin-proxy")
    print("2. Run: cloud_sql_proxy -instances=defimon-ethereum-node:us-central1:defimon-postgres-instance=tcp:5432")
    
    return False

async def main():
    """Main test function"""
    print("🚀 PostgreSQL Database Connection Test")
    print("=" * 50)
    
    # Test Cloud SQL Proxy
    proxy_available = await test_cloud_sql_proxy()
    
    # Test direct connections
    connection_success = await test_direct_connection()
    
    print("\n" + "=" * 50)
    print("📋 Test Results:")
    print(f"  Cloud SQL Proxy: {'✅ Available' if proxy_available else '❌ Not Available'}")
    print(f"  Database Connection: {'✅ Success' if connection_success else '❌ Failed'}")
    
    if not connection_success:
        print("\n🔧 To fix connection issues:")
        print("1. Install Cloud SQL Proxy")
        print("2. Run: cloud_sql_proxy -instances=defimon-ethereum-node:us-central1:defimon-postgres-instance=tcp:5432")
        print("3. Or configure public IP access in Google Cloud Console")
        print("4. Or use connection string: postgresql://defimon_user:Zd8odJnKfXf0pFAkCoaH@localhost:5432/defi_analytics")

if __name__ == "__main__":
    asyncio.run(main())
