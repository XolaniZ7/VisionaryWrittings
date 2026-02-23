# EC2 & Lambda Database Conflicts - Analysis & Resolution

## 🔴 Critical Conflicts Identified

### Conflict 1: Multiple Database Initialization Points
**Problem**: Three different places trying to create the same table with different schemas

1. **EC2 user_data.sh.tpl** - Manual SQL CREATE TABLE
2. **Lambda db_init.js** - Lambda function CREATE TABLE
3. **Lambda database-setup.js** - Another Lambda CREATE TABLE
4. **Prisma (in app)** - ORM schema management

**Risk**: Race conditions, schema mismatches, data corruption

### Conflict 2: Schema Inconsistencies

| Column | EC2 user_data | Lambda db_init.js | Lambda database-setup.js | Issue |
|--------|---------------|-------------------|--------------------------|-------|
| size | BIGINT | INT | BIGINT | Type mismatch |
| content_type | VARCHAR(50) | VARCHAR(50) | VARCHAR(100) | Length mismatch |
| word_count | ❌ Missing | ✅ Present | ❌ Missing | Inconsistent |
| reading_time | ❌ Missing | ✅ Present | ❌ Missing | Inconsistent |
| metadata | ✅ JSON | ❌ Missing | ✅ JSON | Inconsistent |
| processed_date | ✅ DATETIME | ❌ Missing | ✅ DATETIME | Inconsistent |
| created_at | ❌ Missing | ✅ TIMESTAMP | ✅ TIMESTAMP | Inconsistent |
| Indexes | ❌ None | ❌ None | ✅ 2 indexes | Performance impact |
| Engine | Not specified | Not specified | InnoDB | Consistency issue |
| Charset | Not specified | Not specified | utf8mb4 | Encoding issue |

### Conflict 3: Timing Issues
**Problem**: EC2 user_data runs manual SQL BEFORE Prisma schema sync

```bash
# Original flow (PROBLEMATIC):
1. EC2 boots
2. user_data runs manual CREATE TABLE  ← Creates table with Schema A
3. App installs
4. Prisma db push runs                 ← Tries to sync Schema B
5. CONFLICT: Schemas don't match!
```

### Conflict 4: Lambda vs Prisma Ownership
**Problem**: Who owns the schema?
- Lambda functions create tables on S3 events
- EC2 app uses Prisma for schema management
- Both try to be "source of truth"

## ✅ Resolution Strategy

### Solution 1: Single Source of Truth
**Decision**: Prisma owns the schema

**Implementation**:
1. Remove manual SQL from EC2 user_data
2. Update Lambda functions to match Prisma schema
3. Document unified schema in DATABASE_SCHEMA.md
4. Let Prisma `db push` handle all schema changes

### Solution 2: Unified Schema Definition

**Final Schema** (matches Prisma):
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

**Changes Made**:
- ✅ Removed `word_count` and `reading_time` (can be in metadata JSON)
- ✅ Standardized `size` as BIGINT everywhere
- ✅ Standardized `content_type` as VARCHAR(100)
- ✅ Added `metadata` JSON column everywhere
- ✅ Added `processed_date` everywhere
- ✅ Added `created_at` everywhere
- ✅ Added indexes for performance
- ✅ Specified InnoDB engine
- ✅ Specified utf8mb4 charset

### Solution 3: Correct Initialization Order

**New Flow**:
```bash
1. EC2 boots
2. user_data installs dependencies (NO SQL)
3. App clones from GitHub
4. .env file created with DB credentials
5. pnpm install
6. Prisma db push                      ← ONLY schema creation point
7. pnpm build
8. PM2 starts app
```

**Lambda Flow** (unchanged but schema-aligned):
```bash
1. S3 event triggers Lambda
2. Lambda checks if table exists
3. If not, creates with unified schema
4. Processes file
5. Inserts record
```

### Solution 4: Defensive Programming

**Lambda Functions** now use CREATE TABLE IF NOT EXISTS with exact Prisma schema:
- If Prisma already created table → Lambda does nothing
- If Lambda runs first → Creates correct schema
- Either way → No conflicts!

## 🧪 Testing Strategy

### Test 1: EC2 First Scenario
```bash
1. Deploy EC2 (Prisma creates table)
2. Upload file (Lambda uses existing table)
3. Verify: No errors, data consistent
```

### Test 2: Lambda First Scenario
```bash
1. Deploy Lambda
2. Upload file (Lambda creates table)
3. Deploy EC2 (Prisma sees existing table)
4. Verify: No errors, schema matches
```

### Test 3: Concurrent Access
```bash
1. Deploy both simultaneously
2. Upload multiple files
3. Verify: No race conditions, no duplicate tables
```

## 📊 Before vs After Comparison

### Before (Problematic)
```
EC2 user_data:
  CREATE TABLE content_uploads (
    size BIGINT,           ← Different
    content_type VARCHAR(50),  ← Different
    metadata JSON,         ← Present
    processed_date DATETIME,   ← Present
    -- Missing: word_count, reading_time, created_at
  )

Lambda db_init.js:
  CREATE TABLE content_uploads (
    size INT,              ← Different
    content_type VARCHAR(50),
    word_count INT,        ← Present
    reading_time INT,      ← Present
    created_at TIMESTAMP,  ← Present
    -- Missing: metadata, processed_date
  )

Lambda database-setup.js:
  CREATE TABLE content_uploads (
    size BIGINT,
    content_type VARCHAR(100),  ← Different
    metadata JSON,
    processed_date DATETIME,
    created_at TIMESTAMP,
    INDEX idx_processed,   ← Only one with indexes
    INDEX idx_upload_date
  ) ENGINE=InnoDB CHARSET=utf8mb4  ← Only one with engine/charset
```

### After (Unified)
```
All sources use:
  CREATE TABLE content_uploads (
    size BIGINT,
    content_type VARCHAR(100),
    metadata JSON,
    processed_date DATETIME,
    created_at TIMESTAMP,
    INDEX idx_processed,
    INDEX idx_upload_date
  ) ENGINE=InnoDB CHARSET=utf8mb4
```

## 🎯 Benefits of Resolution

1. **No Schema Conflicts**: All sources create identical tables
2. **Prisma as Authority**: Clear ownership of schema
3. **Simpler Deployment**: EC2 user_data doesn't need DB credentials for init
4. **Better Performance**: Indexes added everywhere
5. **Future-Proof**: Easy to add columns via Prisma migrations
6. **Safer**: No manual SQL in bash scripts
7. **Consistent Encoding**: UTF-8 everywhere prevents character issues

## ⚠️ Migration Notes

If you have existing data:

```sql
-- Backup first!
mysqldump -h <HOST> -u <USER> -p<PASS> <DB> content_uploads > backup.sql

-- Add missing columns
ALTER TABLE content_uploads 
  MODIFY COLUMN size BIGINT,
  MODIFY COLUMN content_type VARCHAR(100),
  ADD COLUMN IF NOT EXISTS metadata JSON,
  ADD COLUMN IF NOT EXISTS processed_date DATETIME,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ADD INDEX IF NOT EXISTS idx_processed (processed),
  ADD INDEX IF NOT EXISTS idx_upload_date (upload_date);

-- Convert engine and charset
ALTER TABLE content_uploads 
  ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci;
```

## 📝 Lessons Learned

1. **Single Source of Truth**: Never have multiple places defining the same schema
2. **Use ORMs**: Let Prisma/TypeORM handle schema management
3. **Document Schema**: Keep DATABASE_SCHEMA.md updated
4. **Test Integration**: Always test EC2 + Lambda together
5. **Avoid Manual SQL**: Especially in user_data scripts
