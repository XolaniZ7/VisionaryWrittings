const mysql = require('mysql2/promise');
const { getDatabaseUrl } = require('./db_helper');

exports.handler = async (event) => {
    let connection;
    try {
        const databaseUrl = await getDatabaseUrl();
        connection = await mysql.createConnection(databaseUrl);

        console.log("Connected to database. Creating table if not exists...");

        const createTableQuery = `
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        `;

        await connection.execute(createTableQuery);
        console.log("Table 'content_uploads' ensured with unified schema.");

        return { statusCode: 200, body: "Initialization successful" };
    } catch (error) {
        console.error("Error initializing database:", error);
        throw error;
    } finally {
        if (connection) await connection.end();
    }
};