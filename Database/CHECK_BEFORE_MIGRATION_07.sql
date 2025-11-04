/*==============================================================
  CHECK BEFORE MIGRATION 07

  Purpose: Check data before running Migration 07

  Checks:
  1. Duplicate MobilePhone values
  2. Empty MobilePhone values
  3. Number of records that need fixing

  Usage: Run this file before Migration 07
==============================================================*/

USE [Taketime]
GO

PRINT ''
PRINT '============================================================='
PRINT 'ตรวจสอบข้อมูลก่อนรัน Migration 07'
PRINT '============================================================='
PRINT ''

-- ===================================================================
-- 1. ตรวจสอบข้อมูล MobilePhone ซ้ำ
-- ===================================================================

PRINT '1. ตรวจสอบข้อมูล MobilePhone ที่ซ้ำกัน...'
PRINT ''

DECLARE @DuplicateCount INT

SELECT @DuplicateCount = COUNT(*)
FROM (
    SELECT MobilePhone
    FROM Customer
    WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
    GROUP BY MobilePhone
    HAVING COUNT(*) > 1
) AS Duplicates

IF @DuplicateCount > 0
BEGIN
    PRINT '❌ พบข้อมูล MobilePhone ซ้ำกัน ' + CAST(@DuplicateCount AS VARCHAR) + ' เบอร์'
    PRINT ''
    PRINT 'รายการเบอร์ที่ซ้ำ:'
    PRINT '----------------------------------------'

    SELECT
        MobilePhone AS [เบอร์โทร],
        COUNT(*) AS [จำนวนซ้ำ],
        STRING_AGG(CAST(ID AS VARCHAR), ', ') AS [Customer IDs]
    FROM Customer
    WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
    GROUP BY MobilePhone
    HAVING COUNT(*) > 1
    ORDER BY COUNT(*) DESC, MobilePhone

    PRINT ''
    PRINT '⚠ ต้องแก้ไขข้อมูลซ้ำก่อนรัน Migration 07'
    PRINT ''
END
ELSE
BEGIN
    PRINT '✓ ไม่พบข้อมูล MobilePhone ซ้ำ'
    PRINT ''
END

-- ===================================================================
-- 2. ตรวจสอบข้อมูล MobilePhone ว่างเปล่า
-- ===================================================================

PRINT '2. ตรวจสอบข้อมูล MobilePhone ที่ว่างเปล่า...'
PRINT ''

DECLARE @EmptyCount INT

SELECT @EmptyCount = COUNT(*)
FROM Customer
WHERE MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0

IF @EmptyCount > 0
BEGIN
    PRINT '❌ พบข้อมูล MobilePhone ว่างเปล่า ' + CAST(@EmptyCount AS VARCHAR) + ' รายการ'
    PRINT ''

    -- แสดงรายละเอียด
    SELECT TOP 10
        ID,
        Name,
        MobilePhone,
        Email,
        CASE
            WHEN EXISTS (SELECT 1 FROM Reservation WHERE Customer_MobilePhone = Customer.MobilePhone)
            THEN 'มี Reservation'
            ELSE 'ไม่มี Reservation'
        END AS [สถานะ]
    FROM Customer
    WHERE MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0
    ORDER BY ID

    PRINT ''
    PRINT '⚠ ต้องแก้ไขข้อมูลว่างก่อนรัน Migration 07'
    PRINT ''
END
ELSE
BEGIN
    PRINT '✓ ไม่พบข้อมูล MobilePhone ว่างเปล่า'
    PRINT ''
END

-- ===================================================================
-- 3. สรุปผล
-- ===================================================================

PRINT ''
PRINT '============================================================='
PRINT 'สรุปผล'
PRINT '============================================================='
PRINT ''

IF @DuplicateCount = 0 AND @EmptyCount = 0
BEGIN
    PRINT '✅ ข้อมูลพร้อมสำหรับ Migration 07'
    PRINT ''
    PRINT 'ขั้นตอนถัดไป:'
    PRINT '  1. รัน Migration 07: 07_Add_Customer_Management_Enhancement.sql'
    PRINT '  2. รัน Migration 08: 08_Add_Standard_Accounting_System.sql'
    PRINT ''
END
ELSE
BEGIN
    PRINT '❌ พบปัญหาที่ต้องแก้ไข:'
    PRINT ''
    IF @DuplicateCount > 0
        PRINT '  • MobilePhone ซ้ำ: ' + CAST(@DuplicateCount AS VARCHAR) + ' เบอร์'
    IF @EmptyCount > 0
        PRINT '  • MobilePhone ว่าง: ' + CAST(@EmptyCount AS VARCHAR) + ' รายการ'
    PRINT ''
    PRINT '⚠ วิธีแก้ไข:'
    PRINT '  รัน: FIX_CUSTOMER_DATA_NOW.sql'
    PRINT ''
END

PRINT '============================================================='
