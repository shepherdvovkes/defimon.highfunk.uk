#!/usr/bin/env python3
"""
Check available database users and connection options
"""

import os
import asyncio
import asyncpg
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

async def check_database_users():
    """Check what users are available in the database"""
    print("🔍 Checking Database Users and Connection Options...")
    
    # Get database credentials
    database = os.getenv('GOOGLE_CLOUD_SQL_DATABASE_NAME', 'defi_analytics')
    
    # Try different default users
    default_users = [
        'postgres',
        'defimon_user', 
        'admin',
        'root',
        'default'
    ]
    
    print(f"📊 Database: {database}")
    print("🧪 Testing different user connections...")
    
    for user in default_users:
        try:
            # Try connection without password first
            dsn = f'postgresql://{user}@localhost:5432/{database}'
            print(f"🔗 Trying {user} (no password): {dsn}")
            
            conn = await asyncpg.connect(dsn)
            result = await conn.fetchval('SELECT current_user, version()')
            print(f"✅ {user} connection successful!")
            print(f"📄 Current user: {result[0]}")
            print(f"📄 PostgreSQL version: {result[1]}")
            
            # Check available users
            users = await conn.fetch("SELECT usename FROM pg_user")
            print(f"👥 Available users: {[u['usename'] for u in users]}")
            
            await conn.close()
            return user
            
        except Exception as e:
            print(f"❌ {user} (no password): {e}")
            
            # Try with password
            try:
                password = os.getenv('GOOGLE_CLOUD_SQL_PASSWORD', 'Zd8odJnKfXf0pFAkCoaH')
                dsn = f'postgresql://{user}:{password}@localhost:5432/{database}'
                print(f"🔗 Trying {user} (with password): {dsn}")
                
                conn = await asyncpg.connect(dsn)
                result = await conn.fetchval('SELECT current_user, version()')
                print(f"✅ {user} connection successful!")
                print(f"📄 Current user: {result[0]}")
                print(f"📄 PostgreSQL version: {result[1]}")
                
                # Check available users
                users = await conn.fetch("SELECT usename FROM pg_user")
                print(f"👥 Available users: {[u['usename'] for u in users]}")
                
                await conn.close()
                return user
                
            except Exception as e2:
                print(f"❌ {user} (with password): {e2}")
    
    return None

async def create_user_if_needed(admin_user):
    """Create the defimon_user if we have admin access"""
    if not admin_user:
        print("❌ No admin user found to create defimon_user")
        return False
    
    print(f"\n👤 Creating defimon_user using {admin_user}...")
    
    try:
        password = os.getenv('GOOGLE_CLOUD_SQL_PASSWORD', 'Zd8odJnKfXf0pFAkCoaH')
        database = os.getenv('GOOGLE_CLOUD_SQL_DATABASE_NAME', 'defi_analytics')
        
        # Connect as admin user
        dsn = f'postgresql://{admin_user}@localhost:5432/{database}'
        conn = await asyncpg.connect(dsn)
        
        # Create user
        try:
            await conn.execute(f"""
                CREATE USER defimon_user WITH PASSWORD '{password}';
            """)
            print("✅ defimon_user created successfully")
        except asyncpg.exceptions.DuplicateObjectError:
            print("✅ defimon_user already exists")
        
        # Grant privileges
        await conn.execute(f"""
            GRANT ALL PRIVILEGES ON DATABASE {database} TO defimon_user;
            GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO defimon_user;
            GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO defimon_user;
            ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO defimon_user;
            ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO defimon_user;
        """)
        print("✅ Privileges granted to defimon_user")
        
        await conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Failed to create user: {e}")
        return False

async def main():
    """Main function"""
    print("🚀 Database User Check and Setup")
    print("=" * 50)
    
    # Check available users
    admin_user = await check_database_users()
    
    if admin_user:
        print(f"\n✅ Found working user: {admin_user}")
        
        # Try to create defimon_user
        if await create_user_if_needed(admin_user):
            print("\n🎉 Database user setup completed!")
            print("📊 You can now:")
            print("1. Test connection: python3 test_database_connection.py")
            print("2. Setup schema: python3 setup_database_schema.py")
        else:
            print("\n⚠️ Could not create defimon_user")
            print("💡 You may need to:")
            print("1. Use the existing user for database operations")
            print("2. Check Google Cloud Console for user management")
    else:
        print("\n❌ No working database user found")
        print("💡 You may need to:")
        print("1. Check Google Cloud Console for database users")
        print("2. Reset database password")
        print("3. Create user manually in Google Cloud Console")

if __name__ == "__main__":
    asyncio.run(main())
