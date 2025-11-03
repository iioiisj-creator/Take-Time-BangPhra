/*==============================================================
  Migration: [ชื่อ Migration - เช่น Add_Email_Validation]

  Description:
  - [อธิบายว่า migration นี้ทำอะไร]
  - [เปลี่ยนแปลงอะไรบ้าง]
  - [ผลกระทบต่อระบบ]

  Author: [ชื่อคนสร้าง]
  Created: [วันที่สร้าง - YYYY-MM-DD]
==============================================================*/

USE [Taketime]
GO

-- ===================================================================
-- Check if migration was already applied
-- ===================================================================
DECLARE @MigrationName NVARCHAR(255) = '[ชื่อไฟล์ไม่รวม .sql - เช่น Add_Email_Validation]'
DECLARE @IsApplied TABLE (IsApplied INT)

INSERT INTO @IsApplied
EXEC sp_IsMigrationApplied @MigrationName

IF EXISTS (SELECT 1 FROM @IsApplied WHERE IsApplied = 1)
BEGIN
    PRINT 'Migration already applied: ' + @MigrationName
    RETURN
END
GO

PRINT '============================================================='
PRINT 'Applying Migration: [ชื่อ Migration]'
PRINT '============================================================='
GO

-- ===================================================================
-- STEP 1: Backup (if needed)
-- ===================================================================
PRINT 'Step 1: Creating backup...'
GO

-- ตัวอย่าง: สำรองข้อมูลก่อนแก้ไข
/*
IF OBJECT_ID('dbo.TableName_Backup_YYYYMMDD', 'U') IS NOT NULL
    DROP TABLE dbo.TableName_Backup_YYYYMMDD
GO

SELECT * INTO dbo.TableName_Backup_YYYYMMDD
FROM dbo.TableName
GO

PRINT '✓ Backup created: TableName_Backup_YYYYMMDD'
GO
*/

-- ===================================================================
-- STEP 2: Add/Modify Columns
-- ===================================================================
PRINT 'Step 2: Adding/modifying columns...'
GO

-- ตัวอย่าง: เพิ่มคอลัมน์
/*
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.TableName')
    AND name = 'NewColumn'
)
BEGIN
    ALTER TABLE dbo.TableName
    ADD NewColumn datatype NULL

    PRINT '  ✓ Added column: NewColumn'
END
ELSE
BEGIN
    PRINT '  ✓ Column already exists: NewColumn'
END
GO
*/

-- ===================================================================
-- STEP 3: Populate Default Values (if needed)
-- ===================================================================
PRINT 'Step 3: Setting default values...'
GO

-- ตัวอย่าง: ตั้งค่าเริ่มต้น
/*
UPDATE dbo.TableName
SET NewColumn = 'DefaultValue'
WHERE NewColumn IS NULL
GO

PRINT '  ✓ Default values set'
GO
*/

-- ===================================================================
-- STEP 4: Add Constraints
-- ===================================================================
PRINT 'Step 4: Adding constraints...'
GO

-- ตัวอย่าง: เพิ่ม constraint
/*
-- Make column NOT NULL
ALTER TABLE dbo.TableName
ALTER COLUMN NewColumn datatype NOT NULL
GO

-- Add default constraint
IF NOT EXISTS (
    SELECT * FROM sys.default_constraints
    WHERE name = 'DF_TableName_NewColumn'
)
BEGIN
    ALTER TABLE dbo.TableName
    ADD CONSTRAINT DF_TableName_NewColumn
    DEFAULT ('DefaultValue') FOR NewColumn

    PRINT '  ✓ Added default constraint'
END
GO

-- Add check constraint
IF NOT EXISTS (
    SELECT * FROM sys.check_constraints
    WHERE name = 'CK_TableName_NewColumn'
)
BEGIN
    ALTER TABLE dbo.TableName
    ADD CONSTRAINT CK_TableName_NewColumn
    CHECK (NewColumn IN ('Value1', 'Value2'))

    PRINT '  ✓ Added check constraint'
END
GO
*/

-- ===================================================================
-- STEP 5: Add Indexes (if needed)
-- ===================================================================
PRINT 'Step 5: Adding indexes...'
GO

-- ตัวอย่าง: เพิ่ม index
/*
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_TableName_NewColumn'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_TableName_NewColumn
    ON dbo.TableName (NewColumn)

    PRINT '  ✓ Added index: IX_TableName_NewColumn'
END
GO
*/

-- ===================================================================
-- STEP 6: Create/Modify Stored Procedures (if needed)
-- ===================================================================
PRINT 'Step 6: Creating/modifying stored procedures...'
GO

-- ตัวอย่าง: สร้าง/แก้ไข stored procedure
/*
IF OBJECT_ID('dbo.sp_ProcedureName', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ProcedureName
GO

CREATE PROCEDURE dbo.sp_ProcedureName
    @Parameter1 datatype,
    @Parameter2 datatype
AS
BEGIN
    SET NOCOUNT ON;

    -- Procedure logic here
    SELECT * FROM TableName
    WHERE Column = @Parameter1
END
GO

PRINT '  ✓ Created procedure: sp_ProcedureName'
GO
*/

-- ===================================================================
-- STEP 7: Verification
-- ===================================================================
PRINT 'Step 7: Verifying changes...'
GO

-- ตัวอย่าง: ตรวจสอบผลลัพธ์
/*
SELECT TOP 5 * FROM TableName
GO
*/

-- ===================================================================
-- Record this migration
-- ===================================================================
EXEC sp_RecordMigration
    @MigrationName = '[ชื่อไฟล์ไม่รวม .sql]',
    @AppliedBy = SYSTEM_USER,
    @Success = 1
GO

PRINT ''
PRINT '============================================================='
PRINT 'Migration completed successfully!'
PRINT '============================================================='
PRINT ''
PRINT '✓ Migration recorded: [ชื่อไฟล์ไม่รวม .sql]'
PRINT ''

-- ===================================================================
-- Optional: Rollback script (commented out for safety)
-- ===================================================================
/*
-- ROLLBACK SCRIPT - Use only if you need to undo this migration
USE [Taketime]
GO

PRINT 'Rolling back migration: [ชื่อ Migration]'
GO

-- Reverse the changes made above
-- Example:

-- Drop constraints
ALTER TABLE dbo.TableName DROP CONSTRAINT IF EXISTS DF_TableName_NewColumn
ALTER TABLE dbo.TableName DROP CONSTRAINT IF EXISTS CK_TableName_NewColumn
GO

-- Drop indexes
DROP INDEX IF EXISTS IX_TableName_NewColumn ON dbo.TableName
GO

-- Drop columns
ALTER TABLE dbo.TableName DROP COLUMN IF EXISTS NewColumn
GO

-- Drop procedures
IF OBJECT_ID('dbo.sp_ProcedureName', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ProcedureName
GO

-- Remove migration record
DELETE FROM Database_Migrations
WHERE MigrationName = '[ชื่อไฟล์ไม่รวม .sql]'
GO

PRINT 'Rollback completed.'
GO
*/
