# Database Schema - Unified Definition

## content_uploads Table

This is the single source of truth for the `content_uploads` table schema.
All database initialization code (Prisma, Lambda, etc.) should match this schema.

```sql
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
```

## Schema Management Strategy

1. **Primary Source**: Prisma schema in the application repository
2. **EC2 Initialization**: Prisma `db push` handles schema creation/updates
3. **Lambda Functions**: Use `database-setup.js` for table creation (backup only)
4. **No Manual SQL**: Avoid manual CREATE TABLE in user_data scripts

## Column Definitions

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | INT | NO | AUTO_INCREMENT | Primary key |
| filename | VARCHAR(255) | NO | - | Original filename |
| size | BIGINT | YES | NULL | File size in bytes |
| content_type | VARCHAR(100) | YES | NULL | MIME type |
| upload_date | DATETIME | YES | NULL | When file was uploaded |
| preview | TEXT | YES | NULL | Content preview/excerpt |
| metadata | JSON | YES | NULL | Additional metadata |
| processed | BOOLEAN | YES | FALSE | Processing status flag |
| processed_date | DATETIME | YES | NULL | When processing completed |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Record creation time |

## Migration Notes

- Removed `word_count` and `reading_time` columns (can be computed or stored in metadata JSON)
- Standardized `size` as BIGINT (supports files > 2GB)
- Standardized `content_type` as VARCHAR(100) for longer MIME types
- Added indexes for common query patterns
