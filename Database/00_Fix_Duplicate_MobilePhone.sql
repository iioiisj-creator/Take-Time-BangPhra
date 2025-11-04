/*==============================================================
  Fix Duplicate MobilePhone in Customer Table

  This script finds and fixes duplicate MobilePhone values
  before creating the unique index.
==============================================================*/

USE [Taketime]
GO

SET NOCOUNT ON;

PRINT ''
PRINT '============================================================='
PRINT 'Fixing Duplicate MobilePhone Values'
PRINT '============================================================='
PRINT ''

-- ===================================================================
-- Step 1: Analyze duplicate data
-- ===================================================================

PRINT 'Step 1: Analyzing duplicate MobilePhone values...'
PRINT ''

-- Find all duplicates
SELECT
    MobilePhone,
    COUNT(*) AS DuplicateCount,
    MIN(ID) AS FirstID,
    MAX(ID) AS LastID
INTO #Duplicates
FROM Customer
WHERE MobilePhone IS NOT NULL
GROUP BY MobilePhone
HAVING COUNT(*) > 1

-- Display duplicates
IF EXISTS (SELECT 1 FROM #Duplicates)
BEGIN
    PRINT 'Found duplicate MobilePhone values:'
    PRINT ''

    SELECT
        MobilePhone,
        DuplicateCount,
        FirstID,
        LastID
    FROM #Duplicates
    ORDER BY DuplicateCount DESC, MobilePhone

    DECLARE @DupCount INT
    SELECT @DupCount = COUNT(*) FROM #Duplicates

    PRINT ''
    PRINT 'Total duplicate groups: ' + CAST(@DupCount AS VARCHAR)
    PRINT ''
END
ELSE
BEGIN
    PRINT '✓ No duplicates found!'
    PRINT ''
END

-- Show detailed duplicate records
IF EXISTS (SELECT 1 FROM #Duplicates)
BEGIN
    PRINT 'Detailed duplicate records:'
    PRINT ''

    SELECT
        C.ID,
        C.MobilePhone,
        C.Name,
        C.Email,
        C.Address,
        C.Status,
        (SELECT COUNT(*) FROM Reservation WHERE Customer_MobilePhone = C.MobilePhone) AS ReservationCount
    FROM Customer C
    INNER JOIN #Duplicates D ON C.MobilePhone = D.MobilePhone
    ORDER BY C.MobilePhone, C.ID

    PRINT ''
END

-- Check for empty or null phone numbers
PRINT 'Checking for empty/null MobilePhone values...'
PRINT ''

SELECT
    COUNT(*) AS EmptyCount
FROM Customer
WHERE MobilePhone IS NULL
   OR MobilePhone = ''
   OR LEN(LTRIM(RTRIM(MobilePhone))) = 0

DECLARE @EmptyCount INT
SELECT @EmptyCount = COUNT(*)
FROM Customer
WHERE MobilePhone IS NULL
   OR MobilePhone = ''
   OR LEN(LTRIM(RTRIM(MobilePhone))) = 0

IF @EmptyCount > 0
BEGIN
    PRINT 'Found ' + CAST(@EmptyCount AS VARCHAR) + ' customer(s) with empty/null MobilePhone'
    PRINT ''

    -- Show these records
    SELECT
        ID,
        MobilePhone,
        Name,
        Email,
        Address,
        Status
    FROM Customer
    WHERE MobilePhone IS NULL
       OR MobilePhone = ''
       OR LEN(LTRIM(RTRIM(MobilePhone))) = 0
    ORDER BY ID

    PRINT ''
END
ELSE
BEGIN
    PRINT '✓ No empty/null MobilePhone values found'
    PRINT ''
END

-- ===================================================================
-- Step 2: Provide options for fixing
-- ===================================================================

PRINT ''
PRINT '============================================================='
PRINT 'Fix Options:'
PRINT '============================================================='
PRINT ''
PRINT 'Option 1: Delete customers with empty MobilePhone (if no reservations)'
PRINT 'Option 2: Keep only the first record for each duplicate MobilePhone'
PRINT 'Option 3: Generate unique phone numbers for duplicates'
PRINT ''
PRINT 'Please review the data above and run the appropriate fix script.'
PRINT ''

-- ===================================================================
-- OPTION 1: Delete customers with empty MobilePhone
-- ===================================================================

PRINT '-- OPTION 1: Delete empty MobilePhone records (COMMENTED OUT)'
PRINT '-- Uncomment to use:'
PRINT '/*'
PRINT 'BEGIN TRANSACTION'
PRINT ''
PRINT '-- Delete customers with empty phone and no reservations'
PRINT 'DELETE FROM Customer'
PRINT 'WHERE (MobilePhone IS NULL OR MobilePhone = '''' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0)'
PRINT '  AND NOT EXISTS ('
PRINT '      SELECT 1 FROM Reservation '
PRINT '      WHERE Customer_MobilePhone = Customer.MobilePhone'
PRINT '  )'
PRINT ''
PRINT 'PRINT ''Deleted: '' + CAST(@@ROWCOUNT AS VARCHAR) + '' customer(s)'''
PRINT ''
PRINT 'COMMIT TRANSACTION'
PRINT '*/'
PRINT ''

-- ===================================================================
-- OPTION 2: Keep first record, delete duplicates
-- ===================================================================

PRINT '-- OPTION 2: Keep first record for each phone (COMMENTED OUT)'
PRINT '-- Uncomment to use:'
PRINT '/*'
PRINT 'BEGIN TRANSACTION'
PRINT ''
PRINT '-- Delete duplicate records, keeping the one with lowest ID'
PRINT 'DELETE FROM Customer'
PRINT 'WHERE ID NOT IN ('
PRINT '    SELECT MIN(ID)'
PRINT '    FROM Customer'
PRINT '    WHERE MobilePhone IS NOT NULL'
PRINT '      AND MobilePhone != '''''
PRINT '    GROUP BY MobilePhone'
PRINT ')'
PRINT 'AND MobilePhone IN ('
PRINT '    SELECT MobilePhone'
PRINT '    FROM Customer'
PRINT '    WHERE MobilePhone IS NOT NULL'
PRINT '    GROUP BY MobilePhone'
PRINT '    HAVING COUNT(*) > 1'
PRINT ')'
PRINT ''
PRINT 'PRINT ''Deleted: '' + CAST(@@ROWCOUNT AS VARCHAR) + '' duplicate(s)'''
PRINT ''
PRINT 'COMMIT TRANSACTION'
PRINT '*/'
PRINT ''

-- ===================================================================
-- OPTION 3: Generate unique phone numbers
-- ===================================================================

PRINT '-- OPTION 3: Generate unique phone numbers (COMMENTED OUT)'
PRINT '-- Uncomment to use:'
PRINT '/*'
PRINT 'BEGIN TRANSACTION'
PRINT ''
PRINT '-- Update duplicates with generated phone numbers'
PRINT 'UPDATE C'
PRINT 'SET MobilePhone = ''DUPLICATE_'' + CAST(C.ID AS VARCHAR(10))'
PRINT 'FROM Customer C'
PRINT 'WHERE ID NOT IN ('
PRINT '    SELECT MIN(ID)'
PRINT '    FROM Customer'
PRINT '    WHERE MobilePhone IS NOT NULL'
PRINT '    GROUP BY MobilePhone'
PRINT ')'
PRINT 'AND MobilePhone IN ('
PRINT '    SELECT MobilePhone'
PRINT '    FROM Customer'
PRINT '    WHERE MobilePhone IS NOT NULL'
PRINT '    GROUP BY MobilePhone'
PRINT '    HAVING COUNT(*) > 1'
PRINT ')'
PRINT ''
PRINT 'PRINT ''Updated: '' + CAST(@@ROWCOUNT AS VARCHAR) + '' duplicate(s)'''
PRINT ''
PRINT 'COMMIT TRANSACTION'
PRINT '*/'
PRINT ''

-- Cleanup
DROP TABLE #Duplicates

PRINT ''
PRINT '============================================================='
PRINT 'Analysis complete!'
PRINT '============================================================='
PRINT ''

GO
