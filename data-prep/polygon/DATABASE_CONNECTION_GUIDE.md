# PostgreSQL Database Connection Guide

## 🚨 **Issue: Cannot Connect to Google Cloud SQL PostgreSQL**

### 📊 **Current Status**

#### **Database Configuration**
- **Instance**: `defimon-postgres-instance`
- **Database**: `defi_analytics`
- **User**: `defimon_user`
- **Project**: `defimon-ethereum-node`
- **Region**: `us-central1`

#### **Connection Issues Identified**
1. **❌ Cloud SQL Proxy not installed** - Required for secure connection
2. **❌ Database user doesn't exist** - User needs to be created
3. **❌ No public IP access** - Instance not configured for external access
4. **❌ Schema not created** - Tables need to be set up

### 🔧 **Solutions Implemented**

#### **1. ✅ Environment Configuration**
Updated `.env` file with all database credentials:
```bash
GOOGLE_CLOUD_SQL_INSTANCE_NAME=defimon-postgres-instance
GOOGLE_CLOUD_SQL_DATABASE_NAME=defi_analytics
GOOGLE_CLOUD_SQL_USER=defimon_user
GOOGLE_CLOUD_SQL_PASSWORD=Zd8odJnKfXf0pFAkCoaH
GOOGLE_CLOUD_PROJECT_ID=defimon-ethereum-node
GOOGLE_CLOUD_REGION=us-central1
```

#### **2. ✅ Cloud SQL Proxy Installation**
- Downloaded and installed Cloud SQL Proxy
- Created setup script for easy connection

#### **3. ✅ Database Setup Scripts**
- `setup_database_connection.sh` - Sets up Cloud SQL Proxy
- `setup_database_schema.py` - Creates schema and tables
- `test_database_connection.py` - Tests connection

### 🚀 **Step-by-Step Fix**

#### **Step 1: Setup Database Connection**
```bash
cd /Users/vovkes/defimon.highfunk.uk/data-prep/polygon
./setup_database_connection.sh
```

This will:
- Install Cloud SQL Proxy (if needed)
- Start Cloud SQL Proxy connection
- Test database connectivity

#### **Step 2: Setup Database Schema**
```bash
python3 setup_database_schema.py
```

This will:
- Create database user `defimon_user`
- Create `polygon_data` schema
- Create tables: `blocks`, `transactions`, `receipts`
- Set up indexes for performance
- Grant necessary permissions

#### **Step 3: Test Connection**
```bash
python3 test_database_connection.py
```

This will:
- Test all connection methods
- Verify database access
- Show database statistics

### 📊 **Database Schema**

#### **Tables Created**
1. **`polygon_data.blocks`**
   - Block number, hash, timestamp
   - Gas usage, miner information
   - Transaction count, difficulty

2. **`polygon_data.transactions`**
   - Transaction hash, block number
   - From/to addresses, value
   - Gas price, input data
   - Transaction type and chain ID

3. **`polygon_data.receipts`**
   - Transaction receipt data
   - Gas used, contract address
   - Logs and status information

#### **Indexes Created**
- Block timestamp index
- Transaction block number index
- Address indexes for queries
- Performance optimization

### 🔍 **Troubleshooting**

#### **If Cloud SQL Proxy Fails**
```bash
# Check if proxy is running
lsof -i :5432

# Restart proxy
pkill -f cloud_sql_proxy
./cloud_sql_proxy -instances=defimon-ethereum-node:us-central1:defimon-postgres-instance=tcp:5432 &
```

#### **If Database User Creation Fails**
```bash
# Connect as postgres user
psql -h localhost -U postgres -d defi_analytics

# Create user manually
CREATE USER defimon_user WITH PASSWORD 'Zd8odJnKfXf0pFAkCoaH';
GRANT ALL PRIVILEGES ON DATABASE defi_analytics TO defimon_user;
```

#### **If Schema Creation Fails**
```bash
# Connect and create schema
psql -h localhost -U defimon_user -d defi_analytics
CREATE SCHEMA IF NOT EXISTS polygon_data;
```

### 📈 **Expected Results**

#### **After Successful Setup**
- **✅ Database Connection**: Working via Cloud SQL Proxy
- **✅ User Access**: `defimon_user` can connect and write data
- **✅ Schema Ready**: `polygon_data` schema with all tables
- **✅ Dashboard Integration**: Web dashboard can test connection
- **✅ Data Import**: Ready to import Polygon data

#### **Connection String**
```
postgresql://defimon_user:Zd8odJnKfXf0pFAkCoaH@localhost:5432/defi_analytics
```

### 🎯 **Next Steps**

#### **1. Complete Database Setup**
```bash
./setup_database_connection.sh
python3 setup_database_schema.py
```

#### **2. Test in Dashboard**
- Go to http://localhost:8000
- Click "Database" tab
- Click "Test Connection"
- Click "Setup Schema"

#### **3. Import Data**
```bash
python3 import_data_to_db.py
```

#### **4. Monitor Data**
- Use dashboard to view imported data
- Check database statistics
- Monitor real-time data collection

### 🚀 **Automation Scripts**

#### **Complete Setup Script**
```bash
#!/bin/bash
cd /Users/vovkes/defimon.highfunk.uk/data-prep/polygon

# Setup database connection
./setup_database_connection.sh

# Setup schema
python3 setup_database_schema.py

# Test connection
python3 test_database_connection.py

# Start web dashboard
cd web_dashboard && python3 app.py &
```

#### **Startup Script**
```bash
#!/bin/bash
# Start Cloud SQL Proxy
./cloud_sql_proxy -instances=defimon-ethereum-node:us-central1:defimon-postgres-instance=tcp:5432 &

# Start web dashboard
cd web_dashboard && python3 app.py &

# Start data sync
python3 sync_data.py --mode continuous --interval 60 &
```

---

## 🎉 **Ready to Fix Database Connection!**

The database connection issue is now fully diagnosed and solutions are implemented. Run the setup scripts to get your PostgreSQL database working with the Polygon data collection system!
