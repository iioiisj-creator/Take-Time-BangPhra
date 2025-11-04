/*==============================================================
  CLEAN CUSTOMER DATA - Simple Commands

  Copy and paste these commands one by one to clean customer data
==============================================================*/

USE [Taketime]
GO

-- ===================================================================
-- STEP 1: Check current duplicates
-- ===================================================================

PRINT '===== STEP 1: Checking for duplicates ====='
PRINT ''

-- Show duplicate phone numbers
SELECT
    MobilePhone,
    COUNT(*) AS DuplicateCount
FROM Customer
WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
GROUP BY MobilePhone
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC

-- Show empty phone numbers
SELECT
    COUNT(*) AS EmptyPhoneCount
FROM Customer
WHERE MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0

PRINT ''
PRINT 'If you see duplicates above, run STEP 2'
PRINT ''
GO

-- ===================================================================
-- STEP 2: Clean duplicate data (COPY THIS ENTIRE BLOCK)
-- ===================================================================

/*
PRINT '===== STEP 2: Cleaning duplicate data ====='
PRINT ''

BEGIN TRANSACTION

-- Fix 1: Delete customers with empty phone (no reservations)
DELETE FROM Customer
WHERE (MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0)
  AND NOT EXISTS (SELECT 1 FROM Reservation WHERE Customer_MobilePhone = Customer.MobilePhone)

PRINT 'Deleted customers with empty phone: ' + CAST(@@ROWCOUNT AS VARCHAR)

-- Fix 2: Update empty phones (has reservations)
UPDATE Customer
SET MobilePhone = 'UNKNOWN_' + CAST(ID AS VARCHAR(10))
WHERE (MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0)
  AND EXISTS (SELECT 1 FROM Reservation WHERE Customer_MobilePhone = Customer.MobilePhone)

PRINT 'Updated empty phones: ' + CAST(@@ROWCOUNT AS VARCHAR)

-- Fix 3: Rename duplicate phone numbers (keep first, rename others)
UPDATE C
SET MobilePhone = 'DUP_' + CAST(C.ID AS VARCHAR(10)) + '_' + C.MobilePhone
FROM Customer C
WHERE C.ID NOT IN (
    SELECT MIN(ID)
    FROM Customer
    WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
    GROUP BY MobilePhone
)
AND C.MobilePhone IN (
    SELECT MobilePhone
    FROM Customer
    WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
    GROUP BY MobilePhone
    HAVING COUNT(*) > 1
)

PRINT 'Renamed duplicate phones: ' + CAST(@@ROWCOUNT AS VARCHAR)

-- Verify no duplicates remain
DECLARE @RemainingDups INT
SELECT @RemainingDups = COUNT(*)
FROM (
    SELECT MobilePhone
    FROM Customer
    WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
    GROUP BY MobilePhone
    HAVING COUNT(*) > 1
) AS Dups

IF @RemainingDups = 0
BEGIN
    COMMIT TRANSACTION
    PRINT ''
    PRINT 'SUCCESS! No duplicates remain.'
    PRINT ''
END
ELSE
BEGIN
    ROLLBACK TRANSACTION
    PRINT ''
    PRINT 'ERROR: Still have duplicates. Transaction rolled back.'
    PRINT ''
END

GO
*/

-- ===================================================================
-- STEP 3: Drop failed migration objects
-- ===================================================================

/*
PRINT '===== STEP 3: Dropping failed migration objects ====='
PRINT ''

-- Drop Customer_Audit_Log table if exists
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customer_Audit_Log]') AND type = 'U')
BEGIN
    DROP TABLE [dbo].[Customer_Audit_Log]
    PRINT 'Dropped Customer_Audit_Log table'
END

-- Drop unique index if exists
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'UQ_Customer_MobilePhone')
BEGIN
    DROP INDEX [UQ_Customer_MobilePhone] ON [dbo].[Customer]
    PRINT 'Dropped UQ_Customer_MobilePhone index'
END

-- Delete failed migration records
DELETE FROM Database_Migrations
WHERE MigrationName = '07_Add_Customer_Management_Enhancement'
AND Success = 0

PRINT 'Deleted failed migration records: ' + CAST(@@ROWCOUNT AS VARCHAR)
PRINT ''
PRINT 'Ready to run Migration 07 again!'
PRINT ''

GO
*/

-- ===================================================================
-- INSTRUCTIONS
-- ===================================================================

PRINT '============================================================='
PRINT 'INSTRUCTIONS:'
PRINT '============================================================='
PRINT ''
PRINT '1. Run STEP 1 to check for duplicates'
PRINT ''
PRINT '2. If duplicates found:'
PRINT '   - Uncomment STEP 2 (remove /* and */)'
PRINT '   - Run STEP 2 to clean duplicates'
PRINT ''
PRINT '3. Uncomment and run STEP 3 to drop failed objects'
PRINT ''
PRINT '4. Run Migration 07 again'
PRINT ''
PRINT '============================================================='
PRINT ''

/*
QUICK REFERENCE - Paste these individually:

-- Check duplicates:
SELECT MobilePhone, COUNT(*) FROM Customer WHERE MobilePhone IS NOT NULL GROUP BY MobilePhone HAVING COUNT(*) > 1

-- Delete empty phones (no reservations):
DELETE FROM Customer WHERE (MobilePhone IS NULL OR MobilePhone = '') AND NOT EXISTS (SELECT 1 FROM Reservation WHERE Customer_MobilePhone = Customer.MobilePhone)

-- Drop failed migration table:
DROP TABLE IF EXISTS [dbo].[Customer_Audit_Log]

-- Delete failed migration record:
DELETE FROM Database_Migrations WHERE MigrationName = '07_Add_Customer_Management_Enhancement' AND Success = 0
*/
