/*==============================================================
  Fix Migration 07 - Add Missing Columns

  This script manually adds any missing columns that should
  have been created by Migration 07.

  Run this BEFORE running Migration 07 if you get column errors.
==============================================================*/

USE [Taketime]
GO

SET NOCOUNT ON;

PRINT ''
PRINT '============================================================='
PRINT 'Fixing Missing Columns for Migration 07'
PRINT '============================================================='
PRINT ''

-- Start transaction for safety
BEGIN TRANSACTION

BEGIN TRY

    PRINT 'Step 1: Adding missing columns to Customer table...'
    PRINT ''

    -- TaxID
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'TaxID')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [TaxID] [nvarchar](20) NULL

        PRINT '  ✓ Added TaxID column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ TaxID column already exists'
    END

    -- District
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'District')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [District] [nvarchar](100) NULL

        PRINT '  ✓ Added District column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ District column already exists'
    END

    -- Subdistrict
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'Subdistrict')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [Subdistrict] [nvarchar](100) NULL

        PRINT '  ✓ Added Subdistrict column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ Subdistrict column already exists'
    END

    -- Province
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'Province')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [Province] [nvarchar](100) NULL

        PRINT '  ✓ Added Province column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ Province column already exists'
    END

    -- Postcode
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'Postcode')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [Postcode] [nvarchar](10) NULL

        PRINT '  ✓ Added Postcode column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ Postcode column already exists'
    END

    -- LastUpdated
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'LastUpdated')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [LastUpdated] [datetime] NULL DEFAULT GETDATE()

        PRINT '  ✓ Added LastUpdated column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ LastUpdated column already exists'
    END

    -- LastUpdatedBy_ID
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'LastUpdatedBy_ID')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [LastUpdatedBy_ID] [smallint] NULL

        PRINT '  ✓ Added LastUpdatedBy_ID column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ LastUpdatedBy_ID column already exists'
    END

    -- CreatedDate
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'CreatedDate')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [CreatedDate] [datetime] NULL DEFAULT GETDATE()

        PRINT '  ✓ Added CreatedDate column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ CreatedDate column already exists'
    END

    -- CreatedBy_ID
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'CreatedBy_ID')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [CreatedBy_ID] [smallint] NULL

        PRINT '  ✓ Added CreatedBy_ID column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ CreatedBy_ID column already exists'
    END

    -- IsActive
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'IsActive')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [IsActive] [bit] NOT NULL DEFAULT 1

        PRINT '  ✓ Added IsActive column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ IsActive column already exists'
    END

    PRINT ''
    PRINT 'Step 2: Cleaning up failed migrations...'
    PRINT ''

    -- Delete failed migration records
    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Database_Migrations]'))
    BEGIN
        DELETE FROM Database_Migrations
        WHERE MigrationName = '07_Add_Customer_Management_Enhancement'
        AND Success = 0

        PRINT '  ✓ Removed failed migration records'
    END

    COMMIT TRANSACTION

    PRINT ''
    PRINT '============================================================='
    PRINT '✓ Fix completed successfully!'
    PRINT '============================================================='
    PRINT ''
    PRINT 'Next step: Run Migration 07 script'
    PRINT ''

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorLine INT = ERROR_LINE()

    PRINT ''
    PRINT '============================================================='
    PRINT '✗ Fix failed!'
    PRINT '============================================================='
    PRINT 'Error: ' + @ErrorMessage
    PRINT 'Line: ' + CAST(@ErrorLine AS VARCHAR)
    PRINT '============================================================='
    PRINT ''

    RAISERROR(@ErrorMessage, 16, 1)
END CATCH

GO
