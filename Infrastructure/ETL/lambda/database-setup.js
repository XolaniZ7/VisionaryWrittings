const mysql = require('mysql2/promise');

// Auto-create database table if it doesn't exist
async function ensureTableExists(connection) {
    const createTableSQL = `
        CREATE TABLE IF NOT EXISTS content_uploads (
            id INT AUTO_INCREMENT PRIMARY KEY,
            filename VARCHAR(255) NOT NULL,
            size BIGINT,
            content_type VARCHAR(100),
            upload_date DATETIME,
            preview TEXT,
            metadata JSON,
            processed BOOLEAN DEFAULT FALSE,
            processed_date DATETIME,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_processed (processed),
            INDEX idx_upload_date (upload_date)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `;
    
    try {
        await connection.execute(createTableSQL);
        console.log('Database table ensured');
    } catch (error) {
        console.error('Error creating table:', error);
        throw error;
    }
}

module.exports = { ensureTableExists };