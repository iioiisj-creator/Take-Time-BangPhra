/*==============================================================
  Migration: Add Extra Guest Support to Accommodation

  Purpose:
  - Allow automatic calculation of extra guest charges
  - Admin won't need to manually edit prices for extra guests
  - Backward compatible - won't affect existing reservations

  Created: 2025-11-03
==============================================================*/

USE [Taketime]
GO

-- ===================================================================
-- Check if migration was already applied
-- ===================================================================
DECLARE @MigrationName NVARCHAR(255) = 'Migration_Add_Extra_Guest_Support'
DECLARE @IsApplied TABLE (IsApplied INT)

INSERT INTO @IsApplied
EXEC sp_IsMigrationApplied @MigrationName

IF EXISTS (SELECT 1 FROM @IsApplied WHERE IsApplied = 1)
BEGIN
    PRINT 'Migration already applied: ' + @MigrationName
    RETURN
END
GO

-- ===================================================================
-- STEP 1: Backup current Accommodation data (for safety)
-- ===================================================================
PRINT 'Creating backup of Accommodation table...'
GO

IF OBJECT_ID('dbo.Accommodation_Backup_20251103', 'U') IS NOT NULL
    DROP TABLE dbo.Accommodation_Backup_20251103
GO

SELECT * INTO dbo.Accommodation_Backup_20251103
FROM dbo.Accommodation
GO

PRINT 'Backup created: Accommodation_Backup_20251103'
GO

-- ===================================================================
-- STEP 2: Add new columns to Accommodation table
-- ===================================================================
PRINT 'Adding new columns to Accommodation table...'
GO

-- Add StandardOccupancy (จำนวนผู้เข้าพักมาตรฐาน)
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Accommodation')
    AND name = 'StandardOccupancy'
)
BEGIN
    ALTER TABLE dbo.Accommodation
    ADD StandardOccupancy tinyint NULL

    PRINT '  - Added column: StandardOccupancy'
END
GO

-- Add MaxOccupancy (จำนวนผู้เข้าพักสูงสุดรวมเสริม)
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Accommodation')
    AND name = 'MaxOccupancy'
)
BEGIN
    ALTER TABLE dbo.Accommodation
    ADD MaxOccupancy tinyint NULL

    PRINT '  - Added column: MaxOccupancy'
END
GO

-- Add ExtraGuestPrice (ราคาผู้เข้าพักเสริม/คน/คืน)
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Accommodation')
    AND name = 'ExtraGuestPrice'
)
BEGIN
    ALTER TABLE dbo.Accommodation
    ADD ExtraGuestPrice smallint NULL

    PRINT '  - Added column: ExtraGuestPrice'
END
GO

-- ===================================================================
-- STEP 3: Populate default values for existing data
-- ===================================================================
PRINT 'Setting default values for existing accommodations...'
GO

UPDATE dbo.Accommodation
SET
    StandardOccupancy = ISNULL(StandardOccupancy, People),
    MaxOccupancy = ISNULL(MaxOccupancy, People),
    ExtraGuestPrice = ISNULL(ExtraGuestPrice, 0)
WHERE
    StandardOccupancy IS NULL
    OR MaxOccupancy IS NULL
    OR ExtraGuestPrice IS NULL
GO

PRINT '  - Default values set:'
PRINT '    StandardOccupancy = People (current value)'
PRINT '    MaxOccupancy = People (current value)'
PRINT '    ExtraGuestPrice = 0 (no extra charge initially)'
GO

-- ===================================================================
-- STEP 4: Set NOT NULL constraints with defaults
-- ===================================================================
PRINT 'Setting NOT NULL constraints with defaults...'
GO

ALTER TABLE dbo.Accommodation
ALTER COLUMN StandardOccupancy tinyint NOT NULL
GO

ALTER TABLE dbo.Accommodation
ALTER COLUMN MaxOccupancy tinyint NOT NULL
GO

ALTER TABLE dbo.Accommodation
ALTER COLUMN ExtraGuestPrice smallint NOT NULL
GO

-- Add default constraints for new records
ALTER TABLE dbo.Accommodation
ADD CONSTRAINT DF_Accommodation_StandardOccupancy DEFAULT (2) FOR StandardOccupancy
GO

ALTER TABLE dbo.Accommodation
ADD CONSTRAINT DF_Accommodation_MaxOccupancy DEFAULT (2) FOR MaxOccupancy
GO

ALTER TABLE dbo.Accommodation
ADD CONSTRAINT DF_Accommodation_ExtraGuestPrice DEFAULT (0) FOR ExtraGuestPrice
GO

PRINT '  - Constraints added successfully'
GO

-- ===================================================================
-- STEP 5: Add check constraints for data validation
-- ===================================================================
PRINT 'Adding validation constraints...'
GO

-- MaxOccupancy must be >= StandardOccupancy
IF NOT EXISTS (
    SELECT * FROM sys.check_constraints
    WHERE name = 'CK_Accommodation_MaxOccupancy'
)
BEGIN
    ALTER TABLE dbo.Accommodation
    ADD CONSTRAINT CK_Accommodation_MaxOccupancy
    CHECK (MaxOccupancy >= StandardOccupancy)

    PRINT '  - Added constraint: MaxOccupancy >= StandardOccupancy'
END
GO

-- StandardOccupancy must be > 0
IF NOT EXISTS (
    SELECT * FROM sys.check_constraints
    WHERE name = 'CK_Accommodation_StandardOccupancy'
)
BEGIN
    ALTER TABLE dbo.Accommodation
    ADD CONSTRAINT CK_Accommodation_StandardOccupancy
    CHECK (StandardOccupancy > 0)

    PRINT '  - Added constraint: StandardOccupancy > 0'
END
GO

-- ExtraGuestPrice must be >= 0
IF NOT EXISTS (
    SELECT * FROM sys.check_constraints
    WHERE name = 'CK_Accommodation_ExtraGuestPrice'
)
BEGIN
    ALTER TABLE dbo.Accommodation
    ADD CONSTRAINT CK_Accommodation_ExtraGuestPrice
    CHECK (ExtraGuestPrice >= 0)

    PRINT '  - Added constraint: ExtraGuestPrice >= 0'
END
GO

-- ===================================================================
-- STEP 6: Verify migration results
-- ===================================================================
PRINT ''
PRINT '====================================================================='
PRINT 'Migration completed successfully!'
PRINT '====================================================================='
PRINT ''
PRINT 'Summary of changes:'
PRINT '  1. Added 3 new columns to Accommodation table'
PRINT '  2. Set default values for existing data (no data loss)'
PRINT '  3. Added validation constraints'
PRINT '  4. Created backup table: Accommodation_Backup_20251103'
PRINT ''
PRINT 'Existing reservations are NOT affected.'
PRINT 'New reservations will automatically calculate extra guest charges.'
PRINT ''
PRINT 'Sample data (first 5 accommodations):'
GO

SELECT TOP 5
    ID,
    AccomName,
    People as [Old_People_Column],
    StandardOccupancy,
    MaxOccupancy,
    Price as BasePrice,
    ExtraGuestPrice,
    Status
FROM dbo.Accommodation
ORDER BY ID
GO

-- ===================================================================
-- STEP 7: Example usage
-- ===================================================================
PRINT ''
PRINT '====================================================================='
PRINT 'Example: How to update accommodation settings'
PRINT '====================================================================='
PRINT ''
PRINT '-- Update a specific accommodation to support extra guests'
PRINT 'UPDATE dbo.Accommodation'
PRINT 'SET '
PRINT '    StandardOccupancy = 2,        -- Standard: 2 people'
PRINT '    MaxOccupancy = 4,             -- Can accommodate up to 4 people'
PRINT '    ExtraGuestPrice = 200         -- 200 baht per extra person per night'
PRINT 'WHERE ID = 1'
PRINT ''
PRINT 'Example calculation:'
PRINT '  - Base: 2 people @ 1,000 baht/night'
PRINT '  - Guest books: 3 people x 2 nights'
PRINT '  - Extra guests: 1 person'
PRINT '  - Price per night: 1,000 + (1 x 200) = 1,200 baht'
PRINT '  - Total: 1,200 x 2 = 2,400 baht'
PRINT ''
GO

-- ===================================================================
-- Record this migration
-- ===================================================================
EXEC sp_RecordMigration
    @MigrationName = 'Migration_Add_Extra_Guest_Support',
    @AppliedBy = SYSTEM_USER,
    @Success = 1
GO

PRINT ''
PRINT '✓ Migration recorded successfully'
PRINT ''

-- ===================================================================
-- Optional: Rollback script (commented out for safety)
-- ===================================================================
/*
-- ROLLBACK SCRIPT - Use only if you need to undo this migration
USE [Taketime]
GO

PRINT 'Rolling back migration...'
GO

-- Drop constraints
ALTER TABLE dbo.Accommodation DROP CONSTRAINT IF EXISTS CK_Accommodation_MaxOccupancy
ALTER TABLE dbo.Accommodation DROP CONSTRAINT IF EXISTS CK_Accommodation_StandardOccupancy
ALTER TABLE dbo.Accommodation DROP CONSTRAINT IF EXISTS CK_Accommodation_ExtraGuestPrice
ALTER TABLE dbo.Accommodation DROP CONSTRAINT IF EXISTS DF_Accommodation_StandardOccupancy
ALTER TABLE dbo.Accommodation DROP CONSTRAINT IF EXISTS DF_Accommodation_MaxOccupancy
ALTER TABLE dbo.Accommodation DROP CONSTRAINT IF EXISTS DF_Accommodation_ExtraGuestPrice
GO

-- Drop columns
ALTER TABLE dbo.Accommodation DROP COLUMN IF EXISTS StandardOccupancy
ALTER TABLE dbo.Accommodation DROP COLUMN IF EXISTS MaxOccupancy
ALTER TABLE dbo.Accommodation DROP COLUMN IF EXISTS ExtraGuestPrice
GO

PRINT 'Rollback completed. Data restored from backup if needed.'
GO
*/
