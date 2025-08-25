import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

class Database {
  constructor() {
    this.pool = new Pool({
      host: process.env.POSTGRES_HOST || 'localhost',
      port: process.env.POSTGRES_PORT || 5432,
      database: process.env.POSTGRES_DB || 'admin_dashboard',
      user: process.env.POSTGRES_USER || 'admin_user',
      password: process.env.POSTGRES_PASSWORD || 'password',
      ssl: process.env.POSTGRES_SSL === 'true' ? { rejectUnauthorized: false } : false,
      max: 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    this.pool.on('error', (err) => {
      console.error('Unexpected error on idle client', err);
    });
  }

  async query(text, params) {
    const start = Date.now();
    try {
      const res = await this.pool.query(text, params);
      const duration = Date.now() - start;
      console.debug(`Executed query in ${duration}ms: ${text}`);
      return res;
    } catch (error) {
      console.error('Database query error:', error.message);
      throw error;
    }
  }

  async createL2NetworksTable() {
    const createTableSQL = `
      CREATE TABLE IF NOT EXISTS l2_networks (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        chain_id BIGINT UNIQUE NOT NULL,
        network_type VARCHAR(50) NOT NULL DEFAULT 'L2',
        rpc_url TEXT,
        explorer_url TEXT,
        native_currency VARCHAR(100),
        block_time INTEGER,
        is_active BOOLEAN DEFAULT true,
        last_block_number BIGINT,
        last_sync_time TIMESTAMP WITH TIME ZONE,
        metadata JSONB,
        source VARCHAR(50) NOT NULL DEFAULT 'manual',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_l2_networks_name ON l2_networks(name);
      CREATE INDEX IF NOT EXISTS idx_l2_networks_chain_id ON l2_networks(chain_id);
      CREATE INDEX IF NOT EXISTS idx_l2_networks_network_type ON l2_networks(network_type);
      CREATE INDEX IF NOT EXISTS idx_l2_networks_is_active ON l2_networks(is_active);
      CREATE INDEX IF NOT EXISTS idx_l2_networks_source ON l2_networks(source);
      
      CREATE OR REPLACE FUNCTION update_l2_networks_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = NOW();
          RETURN NEW;
      END;
      $$ language 'plpgsql';
      
      DROP TRIGGER IF EXISTS update_l2_networks_updated_at ON l2_networks;
      CREATE TRIGGER update_l2_networks_updated_at 
          BEFORE UPDATE ON l2_networks
          FOR EACH ROW EXECUTE FUNCTION update_l2_networks_updated_at();
    `;

    try {
      await this.query(createTableSQL);
      console.log('L2 networks table created successfully');
    } catch (error) {
      console.error('Error creating L2 networks table:', error.message);
      throw error;
    }
  }

  async insertOrUpdateNetwork(network) {
    const upsertSQL = `
      INSERT INTO l2_networks (
        name, chain_id, network_type, rpc_url, explorer_url, 
        native_currency, block_time, is_active, last_block_number, 
        last_sync_time, metadata, source
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      ON CONFLICT (chain_id) 
      DO UPDATE SET
        name = EXCLUDED.name,
        network_type = EXCLUDED.network_type,
        rpc_url = EXCLUDED.rpc_url,
        explorer_url = EXCLUDED.explorer_url,
        native_currency = EXCLUDED.native_currency,
        block_time = EXCLUDED.block_time,
        is_active = EXCLUDED.is_active,
        last_block_number = EXCLUDED.last_block_number,
        last_sync_time = EXCLUDED.last_sync_time,
        metadata = EXCLUDED.metadata,
        source = EXCLUDED.source,
        updated_at = NOW()
      RETURNING *;
    `;

    const values = [
      network.name,
      network.chain_id,
      network.network_type || 'L2',
      network.rpc_url,
      network.explorer_url,
      network.native_currency,
      network.block_time,
      network.is_active !== false,
      network.last_block_number,
      network.last_sync_time || new Date(),
      network.metadata ? JSON.stringify(network.metadata) : null,
      network.source || 'sync'
    ];

    try {
      const result = await this.query(upsertSQL, values);
      return result.rows[0];
    } catch (error) {
      console.error('Error upserting network:', error.message);
      throw error;
    }
  }

  async getNetworks(page = 1, limit = 20, search = null) {
    let whereClause = '';
    let params = [];
    let paramIndex = 1;

    if (search && search.length >= 2) {
      whereClause = `WHERE name ILIKE $${paramIndex}`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    const offset = (page - 1) * limit;
    
    const countSQL = `
      SELECT COUNT(*) as total 
      FROM l2_networks 
      ${whereClause}
    `;

    const networksSQL = `
      SELECT 
        id, name, chain_id, network_type, rpc_url, explorer_url,
        native_currency, block_time, is_active, last_block_number,
        last_sync_time, metadata, source, created_at, updated_at
      FROM l2_networks 
      ${whereClause}
      ORDER BY name ASC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    try {
      const [countResult, networksResult] = await Promise.all([
        this.query(countSQL, params),
        this.query(networksSQL, [...params, limit, offset])
      ]);

      return {
        networks: networksResult.rows,
        pagination: {
          page,
          limit,
          total: parseInt(countResult.rows[0].total),
          totalPages: Math.ceil(parseInt(countResult.rows[0].total) / limit)
        }
      };
    } catch (error) {
      console.error('Error getting networks:', error.message);
      throw error;
    }
  }

  async getNetworkByChainId(chainId) {
    const sql = `
      SELECT * FROM l2_networks WHERE chain_id = $1
    `;
    
    try {
      const result = await this.query(sql, [chainId]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error getting network by chain ID:', error.message);
      throw error;
    }
  }

  async healthCheck() {
    try {
      // Simple query to test database connectivity
      const result = await this.query('SELECT 1 as status');
      return { status: 'Connected', timestamp: new Date() };
    } catch (error) {
      return { status: 'Error', error: error.message, timestamp: new Date() };
    }
  }

  async close() {
    await this.pool.end();
    console.log('Database connection closed');
  }
}

export default Database;
