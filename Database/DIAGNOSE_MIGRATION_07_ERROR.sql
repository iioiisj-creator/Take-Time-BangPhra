/*==============================================================
  DIAGNOSE Migration 07 V2 Error

  This script checks why FK constraints are failing
==============================================================*/

USE [Taketime]
GO

PRINT ''
PRINT '============================================================='
PRINT 'Diagnosing Migration 07 V2 FK Constraint Error'
PRINT '============================================================='
PRINT ''

-- ===================================================================
-- Check 1: What Foreign Keys already exist?
-- ===================================================================

PRINT 'Check 1: Existing Foreign Keys on Customer table'
PRINT ''

SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    COL_NAME(fc.parent_object_id, fc.parent_column_id) AS ColumnName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS ReferencedColumn
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fc
    ON fk.object_id = fc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('Customer')
ORDER BY fk.name

PRINT ''

-- ===================================================================
-- Check 2: Check for orphaned LastUpdatedBy_ID values
-- ===================================================================

PRINT 'Check 2: Checking for orphaned LastUpdatedBy_ID values'
PRINT ''

DECLARE @OrphanedLastUpdated INT

SELECT @OrphanedLastUpdated = COUNT(*)
FROM Customer
WHERE LastUpdatedBy_ID IS NOT NULL
  AND LastUpdatedBy_ID NOT IN (SELECT ID FROM Admin)

IF @OrphanedLastUpdated > 0
BEGIN
    PRINT 'ERROR: Found ' + CAST(@OrphanedLastUpdated AS VARCHAR) + ' customers with invalid LastUpdatedBy_ID'
    PRINT ''

    SELECT TOP 10
        ID,
        Name,
        MobilePhone,
        LastUpdatedBy_ID,
        'This Admin ID does not exist!' AS Problem
    FROM Customer
    WHERE LastUpdatedBy_ID IS NOT NULL
      AND LastUpdatedBy_ID NOT IN (SELECT ID FROM Admin)
    ORDER BY ID

    PRINT ''
    PRINT 'Solution: Run the fix script to set these to NULL'
END
ELSE
BEGIN
    PRINT 'OK: All LastUpdatedBy_ID values are valid'
END

PRINT ''

-- ===================================================================
-- Check 3: Check for orphaned CreatedBy_ID values
-- ===================================================================

PRINT 'Check 3: Checking for orphaned CreatedBy_ID values'
PRINT ''

DECLARE @OrphanedCreated INT

SELECT @OrphanedCreated = COUNT(*)
FROM Customer
WHERE CreatedBy_ID IS NOT NULL
  AND CreatedBy_ID NOT IN (SELECT ID FROM Admin)

IF @OrphanedCreated > 0
BEGIN
    PRINT 'ERROR: Found ' + CAST(@OrphanedCreated AS VARCHAR) + ' customers with invalid CreatedBy_ID'
    PRINT ''

    SELECT TOP 10
        ID,
        Name,
        MobilePhone,
        CreatedBy_ID,
        'This Admin ID does not exist!' AS Problem
    FROM Customer
    WHERE CreatedBy_ID IS NOT NULL
      AND CreatedBy_ID NOT IN (SELECT ID FROM Admin)
    ORDER BY ID

    PRINT ''
    PRINT 'Solution: Run the fix script to set these to NULL'
END
ELSE
BEGIN
    PRINT 'OK: All CreatedBy_ID values are valid'
END

PRINT ''

-- ===================================================================
-- Check 4: Check Admin IDs
-- ===================================================================

PRINT 'Check 4: Admin table info'
PRINT ''

SELECT
    COUNT(*) AS TotalAdmins,
    MIN(ID) AS MinID,
    MAX(ID) AS MaxID
FROM Admin

SELECT TOP 5 ID, Username, FirstName, LastName, Status
FROM Admin
ORDER BY ID

PRINT ''

-- ===================================================================
-- Summary and Fix Script
-- ===================================================================

PRINT ''
PRINT '============================================================='
PRINT 'Summary'
PRINT '============================================================='
PRINT ''

IF @OrphanedLastUpdated > 0 OR @OrphanedCreated > 0
BEGIN
    PRINT 'PROBLEM FOUND:'
    PRINT 'Customer table has references to Admin IDs that do not exist'
    PRINT ''
    PRINT 'This prevents Foreign Key creation'
    PRINT ''
    PRINT 'FIX: Run FIX_MIGRATION_07_ORPHANED_DATA.sql'
    PRINT ''
END
ELSE
BEGIN
    PRINT 'All data looks good!'
    PRINT 'Foreign Keys should be able to be created'
    PRINT ''
    PRINT 'If you still get errors, check if FKs already exist'
END

PRINT '============================================================='
