const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const mysql = require('mysql2/promise');
const { getDatabaseUrl } = require('./db_helper');

const s3 = new S3Client(); // Region is inherited from the Lambda environment

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
    console.log('Content ingestion triggered:', JSON.stringify(event, null, 2));
    
    try {
        // Process S3 event
        for (const record of event.Records) {
            const bucket = record.s3.bucket.name;
            const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
            
            console.log(`Processing file: ${key} from bucket: ${bucket}`);
            
            // Get file from S3
            const command = new GetObjectCommand({ Bucket: bucket, Key: key });
            const s3Object = await s3.send(command);
            const fileContent = await s3Object.Body.transformToString();
            
            // Extract metadata
            const metadata = {
                filename: key.split('/').pop(),
                size: s3Object.ContentLength,
                contentType: s3Object.ContentType,
                uploadDate: new Date(record.eventTime),
                content: fileContent.substring(0, 1000) // First 1000 chars for preview
            };
            
            // Get a cached or new database connection
            const connection = await getDbConnection();
            
            // Insert content record (adjust table/fields as needed)
            await connection.execute(
                'INSERT INTO content_uploads (filename, size, content_type, upload_date, preview) VALUES (?, ?, ?, ?, ?)',
                [metadata.filename, metadata.size, metadata.contentType, metadata.uploadDate, metadata.content]
            );
            
            console.log(`Successfully processed: ${key}`);
        }
        
        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Content ingestion completed successfully' })
        };
        
    } catch (error) {
        console.error('Error processing content:', error);
        throw error;
    }
};