#!/usr/bin/env python3
"""
Setup PostgreSQL database schema and user for Polygon data
"""

import os
import asyncio
import asyncpg
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

async def setup_database():
    """Setup database schema and user"""
    print("🗄️ Setting up PostgreSQL Database Schema...")
    
    # Get database credentials
    user = os.getenv('GOOGLE_CLOUD_SQL_USER', 'defimon_user')
    password = os.getenv('GOOGLE_CLOUD_SQL_PASSWORD', 'Zd8odJnKfXf0pFAkCoaH')
    database = os.getenv('GOOGLE_CLOUD_SQL_DATABASE_NAME', 'defi_analytics')
    
    print(f"📊 Database Configuration:")
    print(f"  Database: {database}")
    print(f"  User: {user}")
    
    try:
        # Connect to PostgreSQL (using default postgres user first)
        print("🔗 Connecting to PostgreSQL...")
        
        # Try different connection methods
        connection_strings = [
            f'postgresql://postgres@{user}:{password}@localhost:5432/{database}',
            f'postgresql://postgres@localhost:5432/{database}',
            f'postgresql://{user}:{password}@localhost:5432/{database}'
        ]
        
        conn = None
        for dsn in connection_strings:
            try:
                print(f"🧪 Trying: {dsn}")
                conn = await asyncpg.connect(dsn)
                print(f"✅ Connected successfully!")
                break
            except Exception as e:
                print(f"❌ Failed: {e}")
                continue
        
        if not conn:
            print("❌ Could not connect to database")
            print("💡 You may need to:")
            print("1. Start Cloud SQL Proxy: ./setup_database_connection.sh")
            print("2. Create the database user manually")
            print("3. Check Google Cloud Console for database status")
            return False
        
        # Create user if it doesn't exist
        print("👤 Creating database user...")
        try:
            await conn.execute(f"""
                CREATE USER {user} WITH PASSWORD '{password}';
            """)
            print(f"✅ User {user} created successfully")
        except asyncpg.exceptions.DuplicateObjectError:
            print(f"✅ User {user} already exists")
        except Exception as e:
            print(f"⚠️ Could not create user: {e}")
        
        # Grant privileges
        print("🔐 Granting privileges...")
        try:
            await conn.execute(f"""
                GRANT ALL PRIVILEGES ON DATABASE {database} TO {user};
                GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {user};
                GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO {user};
                ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO {user};
                ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO {user};
            """)
            print("✅ Privileges granted successfully")
        except Exception as e:
            print(f"⚠️ Could not grant privileges: {e}")
        
        # Create polygon_data schema
        print("📋 Creating polygon_data schema...")
        try:
            await conn.execute("""
                CREATE SCHEMA IF NOT EXISTS polygon_data;
            """)
            print("✅ polygon_data schema created")
        except Exception as e:
            print(f"⚠️ Could not create schema: {e}")
        
        # Create tables
        print("📊 Creating tables...")
        
        # Blocks table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS polygon_data.blocks (
                block_number BIGINT PRIMARY KEY,
                block_hash VARCHAR(66) UNIQUE NOT NULL,
                parent_hash VARCHAR(66) NOT NULL,
                timestamp BIGINT NOT NULL,
                gas_limit BIGINT NOT NULL,
                gas_used BIGINT NOT NULL,
                miner VARCHAR(42) NOT NULL,
                difficulty VARCHAR(20),
                total_difficulty VARCHAR(20),
                size INTEGER,
                extra_data TEXT,
                nonce VARCHAR(18),
                base_fee_per_gas VARCHAR(20),
                transactions_count INTEGER DEFAULT 0,
                logs_bloom TEXT,
                state_root VARCHAR(66),
                receipts_root VARCHAR(66),
                transactions_root VARCHAR(66),
                uncle_hash VARCHAR(66),
                mix_hash VARCHAR(66),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        print("✅ blocks table created")
        
        # Transactions table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS polygon_data.transactions (
                hash VARCHAR(66) PRIMARY KEY,
                block_number BIGINT NOT NULL,
                block_hash VARCHAR(66) NOT NULL,
                from_address VARCHAR(42) NOT NULL,
                to_address VARCHAR(42),
                value VARCHAR(50) NOT NULL,
                gas BIGINT NOT NULL,
                gas_price VARCHAR(20) NOT NULL,
                nonce BIGINT NOT NULL,
                input_data TEXT,
                transaction_index INTEGER NOT NULL,
                timestamp BIGINT NOT NULL,
                max_fee_per_gas VARCHAR(20),
                max_priority_fee_per_gas VARCHAR(20),
                type VARCHAR(10),
                chain_id VARCHAR(10),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (block_number) REFERENCES polygon_data.blocks(block_number)
            );
        """)
        print("✅ transactions table created")
        
        # Transaction receipts table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS polygon_data.receipts (
                transaction_hash VARCHAR(66) PRIMARY KEY,
                block_number BIGINT NOT NULL,
                block_hash VARCHAR(66) NOT NULL,
                transaction_index INTEGER NOT NULL,
                from_address VARCHAR(42) NOT NULL,
                to_address VARCHAR(42),
                cumulative_gas_used BIGINT NOT NULL,
                gas_used BIGINT NOT NULL,
                contract_address VARCHAR(42),
                logs TEXT,
                status INTEGER,
                effective_gas_price VARCHAR(20),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (transaction_hash) REFERENCES polygon_data.transactions(hash),
                FOREIGN KEY (block_number) REFERENCES polygon_data.blocks(block_number)
            );
        """)
        print("✅ receipts table created")
        
        # Create indexes
        print("🔍 Creating indexes...")
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_blocks_timestamp ON polygon_data.blocks(timestamp);
            CREATE INDEX IF NOT EXISTS idx_blocks_miner ON polygon_data.blocks(miner);
            CREATE INDEX IF NOT EXISTS idx_transactions_block ON polygon_data.transactions(block_number);
            CREATE INDEX IF NOT EXISTS idx_transactions_from ON polygon_data.transactions(from_address);
            CREATE INDEX IF NOT EXISTS idx_transactions_to ON polygon_data.transactions(to_address);
            CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON polygon_data.transactions(timestamp);
            CREATE INDEX IF NOT EXISTS idx_receipts_block ON polygon_data.receipts(block_number);
        """)
        print("✅ Indexes created")
        
        # Grant permissions to user
        print("🔐 Granting schema permissions...")
        await conn.execute(f"""
            GRANT ALL PRIVILEGES ON SCHEMA polygon_data TO {user};
            GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA polygon_data TO {user};
            GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA polygon_data TO {user};
            ALTER DEFAULT PRIVILEGES IN SCHEMA polygon_data GRANT ALL ON TABLES TO {user};
            ALTER DEFAULT PRIVILEGES IN SCHEMA polygon_data GRANT ALL ON SEQUENCES TO {user};
        """)
        print("✅ Schema permissions granted")
        
        await conn.close()
        
        print("\n🎉 Database setup completed successfully!")
        print("📊 You can now:")
        print("1. Test connection: python3 test_database_connection.py")
        print("2. Import data: python3 import_data_to_db.py")
        print("3. Check dashboard: http://localhost:8000")
        
        return True
        
    except Exception as e:
        print(f"❌ Database setup failed: {e}")
        print("💡 Make sure:")
        print("1. Cloud SQL Proxy is running")
        print("2. You have admin access to the database")
        print("3. The database instance is running")
        return False

async def main():
    """Main function"""
    success = await setup_database()
    if success:
        print("\n✅ Database is ready for Polygon data!")
    else:
        print("\n❌ Database setup failed. Please check the errors above.")

if __name__ == "__main__":
    asyncio.run(main())
