const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Get all L2 networks with pagination and search
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20, search = '', network_type = '' } = req.query;
    const offset = (page - 1) * limit;
    
    let whereClause = 'WHERE 1=1';
    const params = [];
    let paramIndex = 1;
    
    if (search) {
      whereClause += ` AND (name ILIKE $${paramIndex} OR chain_id::text ILIKE $${paramIndex})`;
      params.push(`%${search}%`);
      paramIndex++;
    }
    
    if (network_type) {
      whereClause += ` AND network_type = $${paramIndex}`;
      params.push(network_type);
      paramIndex++;
    }
    
    // Get total count
    const countQuery = `SELECT COUNT(*) FROM l2_networks ${whereClause}`;
    const countResult = await pool.query(countQuery, params);
    const total = parseInt(countResult.rows[0].count);
    
    // Get networks
    const networksQuery = `
      SELECT * FROM l2_networks 
      ${whereClause}
      ORDER BY created_at DESC 
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;
    params.push(limit, offset);
    
    const networksResult = await pool.query(networksQuery, params);
    
    res.json({
      networks: networksResult.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching L2 networks:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get L2 network by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM l2_networks WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Network not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching L2 network:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create new L2 network
router.post('/', async (req, res) => {
  try {
    const {
      name,
      chain_id,
      network_type = 'L2',
      rpc_url,
      explorer_url,
      native_currency,
      block_time,
      is_active = true,
      metadata = {}
    } = req.body;
    
    if (!name || !chain_id) {
      return res.status(400).json({ error: 'Name and chain_id are required' });
    }
    
    const result = await pool.query(`
      INSERT INTO l2_networks (
        name, chain_id, network_type, rpc_url, explorer_url, 
        native_currency, block_time, is_active, metadata, source
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'manual')
      RETURNING *
    `, [name, chain_id, network_type, rpc_url, explorer_url, native_currency, block_time, is_active, metadata]);
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating L2 network:', error);
    if (error.code === '23505') { // Unique violation
      return res.status(409).json({ error: 'Network with this chain_id already exists' });
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update L2 network
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      chain_id,
      network_type,
      rpc_url,
      explorer_url,
      native_currency,
      block_time,
      is_active,
      metadata
    } = req.body;
    
    const result = await pool.query(`
      UPDATE l2_networks 
      SET 
        name = COALESCE($1, name),
        chain_id = COALESCE($2, chain_id),
        network_type = COALESCE($3, network_type),
        rpc_url = COALESCE($4, rpc_url),
        explorer_url = COALESCE($5, explorer_url),
        native_currency = COALESCE($6, native_currency),
        block_time = COALESCE($7, block_time),
        is_active = COALESCE($8, is_active),
        metadata = COALESCE($9, metadata),
        updated_at = NOW()
      WHERE id = $10
      RETURNING *
    `, [name, chain_id, network_type, rpc_url, explorer_url, native_currency, block_time, is_active, metadata, id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Network not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating L2 network:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete L2 network
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM l2_networks WHERE id = $1 RETURNING *', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Network not found' });
    }
    
    res.json({ message: 'Network deleted successfully' });
  } catch (error) {
    console.error('Error deleting L2 network:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get L2 networks statistics
router.get('/stats/summary', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM l2_networks_summary');
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching L2 networks summary:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get sync activity
router.get('/stats/sync-activity', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM l2_networks_sync_activity');
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching sync activity:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Trigger manual sync (calls the L2 sync tool)
router.post('/sync', async (req, res) => {
  try {
    const { force = false } = req.body;
    
    // This would typically call the L2 sync tool
    // For now, we'll return a success message
    res.json({ 
      message: 'Sync initiated', 
      force,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error initiating sync:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
