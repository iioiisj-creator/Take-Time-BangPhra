/*==============================================================
  Check Customer Table Columns

  Run this to see what columns currently exist in Customer table
==============================================================*/

USE [Taketime]
GO

PRINT 'Checking Customer table columns...'
PRINT ''

-- Check which columns exist
SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable,
    CASE WHEN c.is_nullable = 1 THEN 'NULL' ELSE 'NOT NULL' END AS NullableText
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE object_id = OBJECT_ID('dbo.Customer')
ORDER BY c.column_id;

PRINT ''
PRINT 'Checking for Migration 07 required columns...'
PRINT ''

-- Check specific columns we need
DECLARE @HasTaxID BIT = 0
DECLARE @HasDistrict BIT = 0
DECLARE @HasSubdistrict BIT = 0
DECLARE @HasProvince BIT = 0
DECLARE @HasPostcode BIT = 0
DECLARE @HasCreatedDate BIT = 0
DECLARE @HasCreatedBy_ID BIT = 0
DECLARE @HasLastUpdated BIT = 0
DECLARE @HasLastUpdatedBy_ID BIT = 0
DECLARE @HasIsActive BIT = 0

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'TaxID')
    SET @HasTaxID = 1

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'District')
    SET @HasDistrict = 1

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'Subdistrict')
    SET @HasSubdistrict = 1

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'Province')
    SET @HasProvince = 1

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'Postcode')
    SET @HasPostcode = 1

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'CreatedDate')
    SET @HasCreatedDate = 1

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'CreatedBy_ID')
    SET @HasCreatedBy_ID = 1

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'LastUpdated')
    SET @HasLastUpdated = 1

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'LastUpdatedBy_ID')
    SET @HasLastUpdatedBy_ID = 1

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'IsActive')
    SET @HasIsActive = 1

-- Display results
SELECT
    'TaxID' AS ColumnName,
    CASE WHEN @HasTaxID = 1 THEN '✓ EXISTS' ELSE '✗ MISSING' END AS Status
UNION ALL
SELECT 'District', CASE WHEN @HasDistrict = 1 THEN '✓ EXISTS' ELSE '✗ MISSING' END
UNION ALL
SELECT 'Subdistrict', CASE WHEN @HasSubdistrict = 1 THEN '✓ EXISTS' ELSE '✗ MISSING' END
UNION ALL
SELECT 'Province', CASE WHEN @HasProvince = 1 THEN '✓ EXISTS' ELSE '✗ MISSING' END
UNION ALL
SELECT 'Postcode', CASE WHEN @HasPostcode = 1 THEN '✓ EXISTS' ELSE '✗ MISSING' END
UNION ALL
SELECT 'CreatedDate', CASE WHEN @HasCreatedDate = 1 THEN '✓ EXISTS' ELSE '✗ MISSING' END
UNION ALL
SELECT 'CreatedBy_ID', CASE WHEN @HasCreatedBy_ID = 1 THEN '✓ EXISTS' ELSE '✗ MISSING' END
UNION ALL
SELECT 'LastUpdated', CASE WHEN @HasLastUpdated = 1 THEN '✓ EXISTS' ELSE '✗ MISSING' END
UNION ALL
SELECT 'LastUpdatedBy_ID', CASE WHEN @HasLastUpdatedBy_ID = 1 THEN '✓ EXISTS' ELSE '✗ MISSING' END
UNION ALL
SELECT 'IsActive', CASE WHEN @HasIsActive = 1 THEN '✓ EXISTS' ELSE '✗ MISSING' END

PRINT ''
PRINT 'Checking migration history...'
PRINT ''

-- Check migration history
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Database_Migrations]'))
BEGIN
    SELECT
        MigrationName,
        AppliedDate,
        Success,
        CASE WHEN Success = 1 THEN '✓' ELSE '✗' END AS StatusIcon,
        ErrorMessage,
        ExecutionTimeMs,
        AppliedBy
    FROM Database_Migrations
    WHERE MigrationName LIKE '%07%'
    ORDER BY AppliedDate DESC
END
ELSE
BEGIN
    PRINT '✗ Database_Migrations table does not exist'
END

PRINT ''
PRINT 'Done!'
GO
