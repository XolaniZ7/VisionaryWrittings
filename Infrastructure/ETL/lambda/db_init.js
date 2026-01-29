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
                size INT,
                content_type VARCHAR(50),
                upload_date DATETIME,
                preview TEXT,
                word_count INT,
                reading_time INT,
                processed BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `;

        await connection.execute(createTableQuery);

        // Attempt to add the column for existing tables
        try {
            await connection.execute("ALTER TABLE content_uploads ADD COLUMN processed BOOLEAN DEFAULT FALSE");
            console.log("Column 'processed' added to content_uploads.");
        } catch (alterError) {
            // Ignore error if column already exists (Error 1060)
            if (alterError.errno !== 1060) {
                console.warn("Warning: Could not alter table:", alterError.message);
            } else {
                console.log("Column 'processed' already exists.");
            }
        }
        console.log("Table 'content_uploads' ensured.");

        return { statusCode: 200, body: "Initialization successful" };
    } catch (error) {
        console.error("Error initializing database:", error);
        throw error;
    } finally {
        if (connection) await connection.end();
    }
};