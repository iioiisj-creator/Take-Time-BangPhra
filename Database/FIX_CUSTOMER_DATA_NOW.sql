/*==============================================================
  FIX CUSTOMER DATA NOW - แก้ไขข้อมูลทันที

  Purpose: แก้ไขข้อมูล Customer ที่มีปัญหาก่อนรัน Migration 07

  จะทำอะไร:
  1. ลบ Customer ที่เบอร์ว่างและไม่มี Reservation
  2. อัปเดตเบอร์ว่างที่มี Reservation เป็น UNKNOWN_[ID]
  3. เปลี่ยนชื่อเบอร์ซ้ำเป็น DUP_[ID]_[เบอร์เดิม]
  4. เก็บรายการแรกของเบอร์ซ้ำไว้

  ปลอดภัย: ใช้ Transaction - ถ้ามี error จะ rollback

  ใช้งาน:
  - รันไฟล์นี้ใน SQL Server Management Studio
  - กด Execute (F5)
  - หลังจากเสร็จให้รัน Migration 07
==============================================================*/

USE [Taketime]
GO

SET NOCOUNT ON;
SET XACT_ABORT ON; -- Rollback on any error

PRINT ''
PRINT '============================================================='
PRINT 'แก้ไขข้อมูล Customer ก่อนรัน Migration 07'
PRINT 'เริ่มเวลา: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '============================================================='
PRINT ''

-- ===================================================================
-- Begin Transaction
-- ===================================================================

BEGIN TRANSACTION

BEGIN TRY

    -- ===================================================================
    -- Step 1: แสดงข้อมูลก่อนแก้ไข
    -- ===================================================================

    PRINT 'Step 1: ตรวจสอบข้อมูลปัจจุบัน...'
    PRINT ''

    DECLARE @TotalCustomers INT
    DECLARE @EmptyPhone INT
    DECLARE @DuplicatePhone INT

    SELECT @TotalCustomers = COUNT(*) FROM Customer

    SELECT @EmptyPhone = COUNT(*)
    FROM Customer
    WHERE MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0

    SELECT @DuplicatePhone = COUNT(*)
    FROM (
        SELECT MobilePhone
        FROM Customer
        WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
        GROUP BY MobilePhone
        HAVING COUNT(*) > 1
    ) AS Dup

    PRINT '  • ลูกค้าทั้งหมด: ' + CAST(@TotalCustomers AS VARCHAR)
    PRINT '  • เบอร์ว่าง: ' + CAST(@EmptyPhone AS VARCHAR) + ' รายการ'
    PRINT '  • เบอร์ซ้ำ: ' + CAST(@DuplicatePhone AS VARCHAR) + ' เบอร์'
    PRINT ''

    IF @EmptyPhone = 0 AND @DuplicatePhone = 0
    BEGIN
        PRINT '✓ ข้อมูลสะอาดแล้ว ไม่ต้องแก้ไขอะไร'
        COMMIT TRANSACTION
        GOTO FixEnd
    END

    -- ===================================================================
    -- Step 2: ลบ Customer ที่เบอร์ว่างและไม่มี Reservation
    -- ===================================================================

    IF @EmptyPhone > 0
    BEGIN
        PRINT 'Step 2: ลบ Customer ที่เบอร์ว่างและไม่มี Reservation...'
        PRINT ''

        DECLARE @DeletedCount INT = 0

        DELETE FROM Customer
        WHERE (MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0)
          AND NOT EXISTS (
              SELECT 1 FROM Reservation
              WHERE Customer_MobilePhone = Customer.MobilePhone
          )

        SET @DeletedCount = @@ROWCOUNT

        PRINT '  ✓ ลบแล้ว ' + CAST(@DeletedCount AS VARCHAR) + ' รายการ'
        PRINT ''
    END

    -- ===================================================================
    -- Step 3: อัปเดตเบอร์ว่างที่มี Reservation
    -- ===================================================================

    IF @EmptyPhone > 0
    BEGIN
        PRINT 'Step 3: อัปเดตเบอร์ว่างที่มี Reservation...'
        PRINT ''

        DECLARE @UpdatedEmpty INT = 0

        UPDATE Customer
        SET MobilePhone = 'UNKNOWN_' + CAST(ID AS VARCHAR(10))
        WHERE (MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0)
          AND EXISTS (
              SELECT 1 FROM Reservation
              WHERE Customer_MobilePhone = Customer.MobilePhone
                 OR (Customer_MobilePhone IS NULL AND Customer.MobilePhone IS NULL)
                 OR (Customer_MobilePhone = '' AND Customer.MobilePhone = '')
          )

        SET @UpdatedEmpty = @@ROWCOUNT

        PRINT '  ✓ อัปเดตแล้ว ' + CAST(@UpdatedEmpty AS VARCHAR) + ' รายการ → UNKNOWN_[ID]'
        PRINT ''
    END

    -- ===================================================================
    -- Step 4: แก้ไขเบอร์ซ้ำ - เก็บรายการแรก เปลี่ยนชื่อที่เหลือ
    -- ===================================================================

    IF @DuplicatePhone > 0
    BEGIN
        PRINT 'Step 4: แก้ไขเบอร์ซ้ำ...'
        PRINT ''

        -- สร้าง temp table เก็บรายการที่จะเปลี่ยนชื่อ
        SELECT
            C.ID,
            C.MobilePhone AS OldPhone,
            'DUP_' + CAST(C.ID AS VARCHAR(10)) + '_' + C.MobilePhone AS NewPhone
        INTO #CustomersToRename
        FROM Customer C
        WHERE C.MobilePhone IS NOT NULL
          AND C.MobilePhone != ''
          AND C.ID NOT IN (
              -- เก็บ ID แรกของแต่ละเบอร์
              SELECT MIN(ID)
              FROM Customer
              WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
              GROUP BY MobilePhone
          )
          AND EXISTS (
              -- มีคนอื่นใช้เบอร์เดียวกัน
              SELECT 1
              FROM Customer C2
              WHERE C2.MobilePhone = C.MobilePhone
                AND C2.ID != C.ID
          )

        DECLARE @RenamedCount INT
        SELECT @RenamedCount = COUNT(*) FROM #CustomersToRename

        IF @RenamedCount > 0
        BEGIN
            PRINT '  รายการที่จะเปลี่ยนชื่อ:'
            SELECT
                ID AS [Customer ID],
                OldPhone AS [เบอร์เดิม],
                NewPhone AS [เบอร์ใหม่]
            FROM #CustomersToRename
            ORDER BY OldPhone, ID

            PRINT ''

            -- เปลี่ยนชื่อเบอร์
            UPDATE C
            SET MobilePhone = R.NewPhone
            FROM Customer C
            INNER JOIN #CustomersToRename R ON C.ID = R.ID

            PRINT '  ✓ เปลี่ยนชื่อแล้ว ' + CAST(@RenamedCount AS VARCHAR) + ' รายการ → DUP_[ID]_[เบอร์เดิม]'
            PRINT ''

            DROP TABLE #CustomersToRename
        END
        ELSE
        BEGIN
            PRINT '  ⚠ ไม่พบเบอร์ซ้ำที่ต้องเปลี่ยนชื่อ'
            PRINT ''
        END
    END

    -- ===================================================================
    -- Step 5: ตรวจสอบผลลัพธ์
    -- ===================================================================

    PRINT 'Step 5: ตรวจสอบผลลัพธ์หลังแก้ไข...'
    PRINT ''

    DECLARE @NewEmptyPhone INT
    DECLARE @NewDuplicatePhone INT

    SELECT @NewEmptyPhone = COUNT(*)
    FROM Customer
    WHERE MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0

    SELECT @NewDuplicatePhone = COUNT(*)
    FROM (
        SELECT MobilePhone
        FROM Customer
        WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
        GROUP BY MobilePhone
        HAVING COUNT(*) > 1
    ) AS Dup

    PRINT '  • เบอร์ว่างคงเหลือ: ' + CAST(@NewEmptyPhone AS VARCHAR)
    PRINT '  • เบอร์ซ้ำคงเหลือ: ' + CAST(@NewDuplicatePhone AS VARCHAR)
    PRINT ''

    IF @NewEmptyPhone > 0 OR @NewDuplicatePhone > 0
    BEGIN
        PRINT '❌ ยังมีปัญหาคงเหลือ!'
        PRINT ''

        IF @NewEmptyPhone > 0
        BEGIN
            PRINT 'เบอร์ว่างที่เหลือ:'
            SELECT TOP 10 * FROM Customer
            WHERE MobilePhone IS NULL OR MobilePhone = '' OR LEN(LTRIM(RTRIM(MobilePhone))) = 0
        END

        IF @NewDuplicatePhone > 0
        BEGIN
            PRINT 'เบอร์ซ้ำที่เหลือ:'
            SELECT MobilePhone, COUNT(*) AS Cnt
            FROM Customer
            WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
            GROUP BY MobilePhone
            HAVING COUNT(*) > 1
        END

        RAISERROR('ยังมีข้อมูลผิดพลาดอยู่ กรุณาตรวจสอบ', 16, 1)
    END

    PRINT '✓ ข้อมูลสะอาดแล้ว พร้อมรัน Migration 07'
    PRINT ''

    -- ===================================================================
    -- Commit Transaction
    -- ===================================================================

    COMMIT TRANSACTION

    PRINT ''
    PRINT '============================================================='
    PRINT '✅ แก้ไขข้อมูลสำเร็จ!'
    PRINT 'เวลาที่ใช้: ' + CONVERT(VARCHAR, GETDATE(), 120)
    PRINT '============================================================='
    PRINT ''
    PRINT 'ขั้นตอนถัดไป:'
    PRINT '  1. รัน: 07_Add_Customer_Management_Enhancement.sql'
    PRINT '  2. รัน: 08_Add_Standard_Accounting_System.sql'
    PRINT ''

END TRY

BEGIN CATCH

    -- ===================================================================
    -- Rollback on Error
    -- ===================================================================

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    PRINT ''
    PRINT '============================================================='
    PRINT '❌ เกิดข้อผิดพลาด - ยกเลิกการแก้ไขทั้งหมด'
    PRINT '============================================================='
    PRINT ''
    PRINT 'Error Message: ' + ERROR_MESSAGE()
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR)
    PRINT ''

END CATCH

FixEnd:

PRINT ''
PRINT '============================================================='
PRINT 'สิ้นสุดการทำงาน'
PRINT '============================================================='
