const mysql = require('mysql2/promise');
const { getDatabaseUrl } = require('./db_helper');

// Cache the database connection outside of the handler
let dbConnection;

async function getDbConnection() {
    if (dbConnection) return dbConnection;

    try {
        const dbUrl = await getDatabaseUrl();
        dbConnection = await mysql.createConnection(dbUrl);
        return dbConnection;
    } catch (error) {
        console.error("Failed to create database connection:", error);
        dbConnection = null; // Allow retry on next invocation
        throw error;
    }
}

exports.handler = async (event) => {
    console.log('Metadata extraction triggered:', JSON.stringify(event, null, 2));
    
    try {
        // Get a cached or new database connection
        const connection = await getDbConnection();
        
        // Get unprocessed content uploads
        const [rows] = await connection.execute(
            'SELECT * FROM content_uploads WHERE processed = FALSE LIMIT 10'
        );
        
        for (const row of rows) {
            console.log(`Processing metadata for: ${row.filename}`);
            
            // Extract metadata based on file type
            let extractedMetadata = {};
            
            if (row.content_type === 'text/plain' || row.content_type === 'text/markdown') {
                // Extract word count, reading time, etc.
                const wordCount = row.preview.split(/\s+/).length;
                const readingTime = Math.ceil(wordCount / 200); // 200 words per minute
                
                extractedMetadata = {
                    word_count: wordCount,
                    reading_time: readingTime,
                    content_type: 'text',
                    language: 'en' // Could add language detection
                };
            }
            
            // Update record with extracted metadata
            await connection.execute(
                'UPDATE content_uploads SET metadata = ?, processed = TRUE, processed_date = NOW() WHERE id = ?',
                [JSON.stringify(extractedMetadata), row.id]
            );
            
            console.log(`Metadata extracted for: ${row.filename}`);
        }
        
        return {
            statusCode: 200,
            body: JSON.stringify({ 
                message: 'Metadata extraction completed',
                processed: rows.length
            })
        };
        
    } catch (error) {
        console.error('Error extracting metadata:', error);
        throw error;
    }
};