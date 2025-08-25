const fs = require('fs');
const path = require('path');
const pool = require('../config/database');

async function initL2Networks() {
  try {
    console.log('Initializing L2 networks database...');
    
    // Read the SQL initialization script
    const sqlPath = path.join(__dirname, '../../../tools/l2-networks-sync/init-l2-networks-table.sql');
    const sqlContent = fs.readFileSync(sqlPath, 'utf8');
    
    // Split the SQL into individual statements
    const statements = sqlContent
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));
    
    console.log(`Found ${statements.length} SQL statements to execute`);
    
    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      if (statement.trim()) {
        try {
          await pool.query(statement);
          console.log(`✓ Executed statement ${i + 1}/${statements.length}`);
        } catch (error) {
          // Skip if table/view already exists
          if (error.code === '42P07' || error.code === '42710') {
            console.log(`⚠ Statement ${i + 1} skipped (already exists): ${error.message}`);
          } else {
            console.error(`✗ Error executing statement ${i + 1}:`, error.message);
            throw error;
          }
        }
      }
    }
    
    console.log('✅ L2 networks database initialized successfully!');
    
    // Verify the table was created
    const result = await pool.query(`
      SELECT COUNT(*) as count 
      FROM information_schema.tables 
      WHERE table_name = 'l2_networks'
    `);
    
    if (result.rows[0].count > 0) {
      console.log('✅ l2_networks table verified');
      
      // Check if we have any data
      const dataResult = await pool.query('SELECT COUNT(*) as count FROM l2_networks');
      console.log(`📊 Found ${dataResult.rows[0].count} networks in the database`);
    }
    
  } catch (error) {
    console.error('❌ Error initializing L2 networks database:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run if called directly
if (require.main === module) {
  initL2Networks();
}

module.exports = initL2Networks;
