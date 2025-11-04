/*==============================================================
  FIX Migration 07 V2 Orphaned Data

  This script fixes orphaned Admin ID references in Customer table
  so that Foreign Keys can be created successfully
==============================================================*/

USE [Taketime]
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT ''
PRINT '============================================================='
PRINT 'Fixing Orphaned Admin ID References'
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '============================================================='
PRINT ''

-- ===================================================================
-- Begin Transaction
-- ===================================================================

BEGIN TRANSACTION

BEGIN TRY

    -- ===================================================================
    -- Step 1: Check current status
    -- ===================================================================

    PRINT 'Step 1: Checking current status...'
    PRINT ''

    DECLARE @OrphanedLastUpdated INT
    DECLARE @OrphanedCreated INT

    SELECT @OrphanedLastUpdated = COUNT(*)
    FROM Customer
    WHERE LastUpdatedBy_ID IS NOT NULL
      AND LastUpdatedBy_ID NOT IN (SELECT ID FROM Admin)

    SELECT @OrphanedCreated = COUNT(*)
    FROM Customer
    WHERE CreatedBy_ID IS NOT NULL
      AND CreatedBy_ID NOT IN (SELECT ID FROM Admin)

    PRINT '  Orphaned LastUpdatedBy_ID: ' + CAST(@OrphanedLastUpdated AS VARCHAR)
    PRINT '  Orphaned CreatedBy_ID: ' + CAST(@OrphanedCreated AS VARCHAR)
    PRINT ''

    IF @OrphanedLastUpdated = 0 AND @OrphanedCreated = 0
    BEGIN
        PRINT 'No orphaned data found. Nothing to fix!'
        COMMIT TRANSACTION
        GOTO FixEnd
    END

    -- ===================================================================
    -- Step 2: Fix LastUpdatedBy_ID
    -- ===================================================================

    IF @OrphanedLastUpdated > 0
    BEGIN
        PRINT 'Step 2: Fixing LastUpdatedBy_ID...'
        PRINT ''

        -- Show what will be changed
        PRINT '  Records that will be updated:'
        SELECT TOP 10
            ID,
            Name,
            LastUpdatedBy_ID AS InvalidAdminID,
            'Will be set to NULL' AS Action
        FROM Customer
        WHERE LastUpdatedBy_ID IS NOT NULL
          AND LastUpdatedBy_ID NOT IN (SELECT ID FROM Admin)

        PRINT ''

        -- Fix them
        UPDATE Customer
        SET LastUpdatedBy_ID = NULL
        WHERE LastUpdatedBy_ID IS NOT NULL
          AND LastUpdatedBy_ID NOT IN (SELECT ID FROM Admin)

        PRINT '  Updated ' + CAST(@@ROWCOUNT AS VARCHAR) + ' records'
        PRINT ''
    END
    ELSE
    BEGIN
        PRINT 'Step 2: LastUpdatedBy_ID - No orphaned data'
        PRINT ''
    END

    -- ===================================================================
    -- Step 3: Fix CreatedBy_ID
    -- ===================================================================

    IF @OrphanedCreated > 0
    BEGIN
        PRINT 'Step 3: Fixing CreatedBy_ID...'
        PRINT ''

        -- Show what will be changed
        PRINT '  Records that will be updated:'
        SELECT TOP 10
            ID,
            Name,
            CreatedBy_ID AS InvalidAdminID,
            'Will be set to NULL' AS Action
        FROM Customer
        WHERE CreatedBy_ID IS NOT NULL
          AND CreatedBy_ID NOT IN (SELECT ID FROM Admin)

        PRINT ''

        -- Fix them
        UPDATE Customer
        SET CreatedBy_ID = NULL
        WHERE CreatedBy_ID IS NOT NULL
          AND CreatedBy_ID NOT IN (SELECT ID FROM Admin)

        PRINT '  Updated ' + CAST(@@ROWCOUNT AS VARCHAR) + ' records'
        PRINT ''
    END
    ELSE
    BEGIN
        PRINT 'Step 3: CreatedBy_ID - No orphaned data'
        PRINT ''
    END

    -- ===================================================================
    -- Step 4: Verify fix
    -- ===================================================================

    PRINT 'Step 4: Verifying fix...'
    PRINT ''

    DECLARE @RemainingOrphans INT

    SELECT @RemainingOrphans = COUNT(*)
    FROM Customer
    WHERE (LastUpdatedBy_ID IS NOT NULL AND LastUpdatedBy_ID NOT IN (SELECT ID FROM Admin))
       OR (CreatedBy_ID IS NOT NULL AND CreatedBy_ID NOT IN (SELECT ID FROM Admin))

    IF @RemainingOrphans > 0
    BEGIN
        PRINT 'WARNING: Still have ' + CAST(@RemainingOrphans AS VARCHAR) + ' orphaned records!'
        RAISERROR('Fix incomplete', 16, 1)
    END
    ELSE
    BEGIN
        PRINT 'SUCCESS: All orphaned data fixed!'
    END

    PRINT ''

    -- ===================================================================
    -- Commit Transaction
    -- ===================================================================

    COMMIT TRANSACTION

    PRINT ''
    PRINT '============================================================='
    PRINT 'Fix completed successfully!'
    PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 120)
    PRINT '============================================================='
    PRINT ''
    PRINT 'Next step: Re-run Migration 07 V2'
    PRINT 'File: 07_Add_Customer_Management_Enhancement_v2.sql'
    PRINT ''

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorLine INT = ERROR_LINE()

    PRINT ''
    PRINT '============================================================='
    PRINT 'Fix failed!'
    PRINT '============================================================='
    PRINT 'Error: ' + @ErrorMessage
    PRINT 'Line: ' + CAST(@ErrorLine AS VARCHAR)
    PRINT ''

    THROW

END CATCH

FixEnd:

PRINT ''
PRINT '============================================================='
PRINT 'Script completed'
PRINT '============================================================='
