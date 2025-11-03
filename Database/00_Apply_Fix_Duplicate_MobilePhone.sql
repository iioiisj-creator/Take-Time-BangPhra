/*==============================================================
  Apply Fix for Duplicate MobilePhone

  This script automatically fixes duplicate MobilePhone values:
  1. Deletes customers with empty phone (no reservations)
  2. For duplicates, keeps first record and updates others

  SAFE TO RUN - Uses transactions and checks for reservations
==============================================================*/

USE [Taketime]
GO

SET NOCOUNT ON;

PRINT ''
PRINT '============================================================='
PRINT 'Applying Fix for Duplicate MobilePhone Values'
PRINT '============================================================='
PRINT ''

BEGIN TRANSACTION

BEGIN TRY

    -- ===================================================================
    -- Step 1: Delete customers with empty MobilePhone (no reservations)
    -- ===================================================================

    PRINT 'Step 1: Removing customers with empty MobilePhone...'
    PRINT ''

    -- First, show what will be deleted
    DECLARE @EmptyNoReservations INT
    SELECT @EmptyNoReservations = COUNT(*)
    FROM Customer C
    WHERE (C.MobilePhone IS NULL OR C.MobilePhone = '' OR LEN(LTRIM(RTRIM(C.MobilePhone))) = 0)
      AND NOT EXISTS (
          SELECT 1 FROM Reservation R
          WHERE R.Customer_MobilePhone = C.MobilePhone
      )

    IF @EmptyNoReservations > 0
    BEGIN
        PRINT '  Found ' + CAST(@EmptyNoReservations AS VARCHAR) + ' customer(s) with empty phone and no reservations'

        -- Delete them
        DELETE FROM Customer
        WHERE (MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0)
          AND NOT EXISTS (
              SELECT 1 FROM Reservation
              WHERE Customer_MobilePhone = Customer.MobilePhone
          )

        PRINT '  ✓ Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' customer(s)'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ No customers with empty phone to delete'
    END

    PRINT ''

    -- ===================================================================
    -- Step 2: Update customers with empty phone (has reservations)
    -- ===================================================================

    PRINT 'Step 2: Updating customers with empty phone (has reservations)...'
    PRINT ''

    -- Generate unique phone for customers with empty phone but have reservations
    DECLARE @EmptyWithReservations INT
    SELECT @EmptyWithReservations = COUNT(*)
    FROM Customer C
    WHERE (C.MobilePhone IS NULL OR C.MobilePhone = '' OR LEN(LTRIM(RTRIM(C.MobilePhone))) = 0)
      AND EXISTS (
          SELECT 1 FROM Reservation R
          WHERE R.Customer_MobilePhone = C.MobilePhone
      )

    IF @EmptyWithReservations > 0
    BEGIN
        PRINT '  Found ' + CAST(@EmptyWithReservations AS VARCHAR) + ' customer(s) with empty phone but have reservations'

        -- Update with generated phone number
        UPDATE Customer
        SET MobilePhone = 'UNKNOWN_' + CAST(ID AS VARCHAR(10))
        WHERE (MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0)
          AND EXISTS (
              SELECT 1 FROM Reservation
              WHERE Customer_MobilePhone = Customer.MobilePhone
          )

        PRINT '  ✓ Updated ' + CAST(@@ROWCOUNT AS VARCHAR) + ' customer(s) with generated phone numbers'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ No customers with empty phone (with reservations) to update'
    END

    PRINT ''

    -- ===================================================================
    -- Step 3: Handle duplicate MobilePhone values
    -- ===================================================================

    PRINT 'Step 3: Handling duplicate MobilePhone values...'
    PRINT ''

    -- Find duplicates
    SELECT
        MobilePhone,
        COUNT(*) AS DuplicateCount
    INTO #Duplicates
    FROM Customer
    WHERE MobilePhone IS NOT NULL
      AND MobilePhone != ''
    GROUP BY MobilePhone
    HAVING COUNT(*) > 1

    DECLARE @DuplicateGroups INT
    SELECT @DuplicateGroups = COUNT(*) FROM #Duplicates

    IF @DuplicateGroups > 0
    BEGIN
        PRINT '  Found ' + CAST(@DuplicateGroups AS VARCHAR) + ' duplicate MobilePhone group(s)'
        PRINT ''

        -- For each duplicate, update all but the first one
        DECLARE @Phone NVARCHAR(30)
        DECLARE @Updated INT = 0

        DECLARE phone_cursor CURSOR FOR
        SELECT MobilePhone FROM #Duplicates

        OPEN phone_cursor
        FETCH NEXT FROM phone_cursor INTO @Phone

        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT '  Processing duplicates for phone: ' + @Phone

            -- Get the first (keep) ID
            DECLARE @KeepID BIGINT
            SELECT @KeepID = MIN(ID)
            FROM Customer
            WHERE MobilePhone = @Phone

            -- Update others
            UPDATE Customer
            SET MobilePhone = 'DUP_' + CAST(ID AS VARCHAR(10)) + '_' + @Phone
            WHERE MobilePhone = @Phone
              AND ID != @KeepID

            SET @Updated = @Updated + @@ROWCOUNT

            FETCH NEXT FROM phone_cursor INTO @Phone
        END

        CLOSE phone_cursor
        DEALLOCATE phone_cursor

        PRINT ''
        PRINT '  ✓ Updated ' + CAST(@Updated AS VARCHAR) + ' duplicate customer(s)'

        DROP TABLE #Duplicates
    END
    ELSE
    BEGIN
        PRINT '  ⚠ No duplicate MobilePhone values found'
        DROP TABLE #Duplicates
    END

    PRINT ''

    -- ===================================================================
    -- Step 4: Verify no duplicates remain
    -- ===================================================================

    PRINT 'Step 4: Verifying fix...'
    PRINT ''

    DECLARE @RemainingDuplicates INT
    SELECT @RemainingDuplicates = COUNT(*)
    FROM (
        SELECT MobilePhone, COUNT(*) AS Cnt
        FROM Customer
        WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
        GROUP BY MobilePhone
        HAVING COUNT(*) > 1
    ) AS Dups

    IF @RemainingDuplicates = 0
    BEGIN
        PRINT '  ✓ No duplicate MobilePhone values remain!'
        PRINT ''

        COMMIT TRANSACTION

        PRINT ''
        PRINT '============================================================='
        PRINT '✓ Fix applied successfully!'
        PRINT '============================================================='
        PRINT ''
        PRINT 'Next steps:'
        PRINT '1. Run Migration 07 again'
        PRINT '2. The unique index should now be created successfully'
        PRINT ''
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION

        PRINT '  ✗ Still have ' + CAST(@RemainingDuplicates AS VARCHAR) + ' duplicate(s)!'
        PRINT ''
        PRINT '============================================================='
        PRINT '✗ Fix failed - Transaction rolled back'
        PRINT '============================================================='
        PRINT ''
        PRINT 'Please run 00_Fix_Duplicate_MobilePhone.sql to analyze'
        PRINT ''
    END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorLine INT = ERROR_LINE()

    PRINT ''
    PRINT '============================================================='
    PRINT '✗ Error occurred!'
    PRINT '============================================================='
    PRINT 'Error: ' + @ErrorMessage
    PRINT 'Line: ' + CAST(@ErrorLine AS VARCHAR)
    PRINT '============================================================='
    PRINT ''

    RAISERROR(@ErrorMessage, 16, 1)
END CATCH

GO
