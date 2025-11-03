# 📋 Database Migration Guide - Take Time BangPhra

## ⚠️ สิ่งสำคัญก่อนเริ่ม Migrate

### 1. **Backup Database ก่อนเสมอ!**
```sql
-- ใน SQL Server Management Studio (SSMS)
-- คลิกขวาที่ Database → Tasks → Back Up...
-- หรือใช้คำสั่ง:

BACKUP DATABASE [Taketime]
TO DISK = 'C:\Backup\Taketime_Backup_Before_Migration.bak'
WITH FORMAT, INIT, COMPRESSION;
```

### 2. **เช็คว่าเชื่อมต่อ Database ได้**
```sql
USE [Taketime]
GO
SELECT @@VERSION
```

---

## 📂 รายการ Migration Files (รันตามลำดับนี้)

| ลำดับ | ไฟล์ | คำอธิบาย | สถานะ |
|------|------|----------|-------|
| 0 | `00_Init_Migration_System.sql` | สร้างระบบติดตาม migration | ✅ รันก่อน |
| 1 | `07_Add_Customer_Management_Enhancement.sql` | ระบบจัดการลูกค้าและ audit log | 🆕 ใหม่ |
| 2 | `08_Add_Standard_Accounting_System.sql` | ระบบบัญชีมาตรฐาน (Credit/Debit Note) | 🆕 ใหม่ |

**หมายเหตุ:** Migration 03-06 เป็น PMS features ที่อาจรันในอนาคต (ไม่จำเป็นสำหรับระบบปัจจุบัน)

---

## 🚀 ขั้นตอนการ Migrate (ละเอียด)

### ✅ ขั้นตอนที่ 1: เปิด SQL Server Management Studio (SSMS)

1. เปิดโปรแกรม **SQL Server Management Studio**
2. เชื่อมต่อกับ SQL Server ของคุณ
3. ใน **Object Explorer** ให้เลือก database: **Taketime**

---

### ✅ ขั้นตอนที่ 2: เปิด Migration Files

#### 2.1 รัน Migration 00 (ครั้งแรกเท่านั้น)

1. ใน SSMS: `File` → `Open` → `File...`
2. เลือกไฟล์: `Database/00_Init_Migration_System.sql`
3. คลิกที่ dropdown ด้านบน เลือก database: **Taketime**
4. กด `F5` หรือคลิก **Execute**
5. ดูใน **Messages** ควรเห็น:
   ```
   ✓ Created Database_Migrations table
   ✓ Created sp_RecordMigration stored procedure
   ✓ Migration system initialized successfully
   ```

---

#### 2.2 รัน Migration 07 - Customer Management

1. เปิดไฟล์: `Database/07_Add_Customer_Management_Enhancement.sql`
2. เลือก database: **Taketime**
3. กด `F5` (Execute)
4. ดูใน **Messages** ควรเห็น:
   ```
   ============================================================
   Migration: 07_Add_Customer_Management_Enhancement
   ============================================================
   ✓ Created Customer_Audit_Log table
   ✓ Added columns to Customer table
   ✓ Created sp_UpsertCustomer
   ✓ Created sp_GetCustomer
   ✓ Created sp_SearchCustomers
   ✓ Created sp_GetCustomerAuditHistory
   ✓ Updated existing customers
   ============================================================
   Migration completed successfully!
   ============================================================
   ```

**ถ้ามี Error:**
- ถ้าเห็น: `⚠ Migration already applied` → **ปกติ** (ข้าม)
- ถ้ามี Error อื่น → หยุดและแจ้งทีม

---

#### 2.3 รัน Migration 08 - Accounting System

1. เปิดไฟล์: `Database/08_Add_Standard_Accounting_System.sql`
2. เลือก database: **Taketime**
3. กด `F5` (Execute)
4. ดูใน **Messages** ควรเห็น:
   ```
   ============================================================
   Migration: 08_Add_Standard_Accounting_System
   ============================================================
   ✓ Created Credit_Note table
   ✓ Created Credit_Note_Detail table
   ✓ Created Debit_Note table
   ✓ Created Debit_Note_Detail table
   ✓ Added columns to Account_Receipt table
   ✓ Created sp_CreateCreditNote
   ✓ Created sp_CreateDebitNote
   ✓ Created sp_GetFrontTeamDailySummary
   ✓ Created sp_GetFrontTeamTransactions
   ✓ Created v_CheckDocument_Summary view
   ✓ Updated existing receipts
   ============================================================
   Migration completed successfully!
   ============================================================

   Standard Accounting System Features:
     ✓ Credit Note (ใบลดหนี้) for refunds and adjustments
     ✓ Debit Note (ใบเพิ่มหนี้) for additional charges
     ✓ Transaction date tracking
     ✓ Front team transaction separation
     ✓ Revenue categorization
     ✓ Daily summary reporting
   ```

**ระยะเวลา:** ประมาณ 30-60 วินาที

---

### ✅ ขั้นตอนที่ 3: ตรวจสอบว่า Migration สำเร็จ

รันคำสั่งนี้เพื่อดูประวัติ migration:

```sql
USE [Taketime]
GO

-- ดู migration ทั้งหมดที่รันไปแล้ว
SELECT
    MigrationName,
    AppliedDate,
    Success,
    ExecutionTimeMs,
    AppliedBy
FROM Database_Migrations
ORDER BY AppliedDate DESC;
```

**ผลลัพธ์ที่คาดหวัง:**
```
MigrationName                                | AppliedDate         | Success | ExecutionTimeMs
---------------------------------------------|---------------------|---------|----------------
08_Add_Standard_Accounting_System            | 2025-11-03 10:30:00 | 1       | 45000
07_Add_Customer_Management_Enhancement       | 2025-11-03 10:29:00 | 1       | 30000
00_Init_Migration_System                     | 2025-11-03 10:28:00 | 1       | 1000
```

---

### ✅ ขั้นตอนที่ 4: ทดสอบว่าทำงานได้

#### ทดสอบ Customer Management:

```sql
-- ทดสอบค้นหาลูกค้า
EXEC sp_SearchCustomers @SearchTerm = 'test', @ActiveOnly = 1, @MaxResults = 10;

-- ทดสอบดูข้อมูลลูกค้า
EXEC sp_GetCustomer @MobilePhone = '0812345678';
```

#### ทดสอบ Accounting System:

```sql
-- ทดสอบดูสรุปรายรับทีม Front วันนี้
EXEC sp_GetFrontTeamDailySummary
    @StartDate = '2025-11-03',
    @EndDate = '2025-11-03';

-- ทดสอบดูรายการธุรกรรมวันนี้
EXEC sp_GetFrontTeamTransactions @TransactionDate = '2025-11-03';

-- ดูข้อมูลใน Account_Receipt ที่ถูก update
SELECT TOP 10
    ID,
    Receipt_Number,
    TransactionDate,
    IsCheckIn,
    IsFrontTransaction,
    RevenueCategory,
    Total_Amount
FROM Account_Receipt
ORDER BY Created_Date DESC;
```

---

## ✅ ขั้นตอนที่ 5: Verify ข้อมูลเดิมไม่เสียหาย

```sql
-- ตรวจสอบว่าข้อมูลลูกค้าเดิมยังอยู่
SELECT COUNT(*) AS TotalCustomers FROM Customer WHERE Status = 1;

-- ตรวจสอบว่าใบเสร็จเดิมยังอยู่
SELECT COUNT(*) AS TotalReceipts FROM Account_Receipt WHERE Status = 1;

-- ตรวจสอบว่าไม่มี NULL ใน column ใหม่ที่เป็น NOT NULL
SELECT COUNT(*) AS InvalidRecords
FROM Account_Receipt
WHERE IsCheckIn IS NULL OR IsFrontTransaction IS NULL;
-- ต้องได้ 0
```

---

## 🔄 ถ้าต้องการ Rollback (กรณีมีปัญหา)

### วิธีที่ 1: Restore จาก Backup (แนะนำ)

```sql
-- 1. ยกเลิกการเชื่อมต่อทั้งหมด
USE master;
GO

ALTER DATABASE [Taketime] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- 2. Restore database
RESTORE DATABASE [Taketime]
FROM DISK = 'C:\Backup\Taketime_Backup_Before_Migration.bak'
WITH REPLACE;
GO

-- 3. เปิดการเชื่อมต่อกลับ
ALTER DATABASE [Taketime] SET MULTI_USER;
GO
```

### วิธีที่ 2: ลบ Tables/Procedures ที่สร้างใหม่ (ไม่แนะนำ)

**สำหรับ Migration 07:**
```sql
USE [Taketime]
GO

-- ลบ stored procedures
DROP PROCEDURE IF EXISTS sp_DeleteCustomer;
DROP PROCEDURE IF EXISTS sp_GetCustomerAuditHistory;
DROP PROCEDURE IF EXISTS sp_SearchCustomers;
DROP PROCEDURE IF EXISTS sp_GetCustomer;
DROP PROCEDURE IF EXISTS sp_UpsertCustomer;

-- ลบ tables
DROP TABLE IF EXISTS Customer_Audit_Log;

-- ลบ columns ที่เพิ่มใน Customer table
ALTER TABLE Customer DROP COLUMN IF EXISTS IsActive;
ALTER TABLE Customer DROP COLUMN IF EXISTS CreatedBy_ID;
ALTER TABLE Customer DROP COLUMN IF EXISTS CreatedDate;
ALTER TABLE Customer DROP COLUMN IF EXISTS LastUpdatedBy_ID;
ALTER TABLE Customer DROP COLUMN IF EXISTS LastUpdated;
```

**สำหรับ Migration 08:**
```sql
USE [Taketime]
GO

-- ลบ views
DROP VIEW IF EXISTS v_CheckDocument_Summary;

-- ลบ stored procedures
DROP PROCEDURE IF EXISTS sp_GetRevenueSummaryByPaymentChannel;
DROP PROCEDURE IF EXISTS sp_GetRevenueSummaryByCategory;
DROP PROCEDURE IF EXISTS sp_GetFrontTeamTransactions;
DROP PROCEDURE IF EXISTS sp_GetFrontTeamDailySummary;
DROP PROCEDURE IF EXISTS sp_CreateDebitNote;
DROP PROCEDURE IF EXISTS sp_CreateCreditNote;

-- ลบ tables (ลบ detail ก่อน master)
DROP TABLE IF EXISTS Debit_Note_Detail;
DROP TABLE IF EXISTS Debit_Note;
DROP TABLE IF EXISTS Credit_Note_Detail;
DROP TABLE IF EXISTS Credit_Note;

-- ลบ columns ที่เพิ่มใน Account_Receipt
ALTER TABLE Account_Receipt DROP COLUMN IF EXISTS ReferenceDocument;
ALTER TABLE Account_Receipt DROP COLUMN IF EXISTS RevenueCategory;
ALTER TABLE Account_Receipt DROP COLUMN IF EXISTS IsFrontTransaction;
ALTER TABLE Account_Receipt DROP COLUMN IF EXISTS IsCheckIn;
ALTER TABLE Account_Receipt DROP COLUMN IF EXISTS TransactionDate;
```

---

## 📊 เช็คสถานะ Database หลัง Migration

```sql
-- ดูว่ามี table อะไรบ้าง
SELECT
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME IN (
        'Customer_Audit_Log',
        'Credit_Note',
        'Credit_Note_Detail',
        'Debit_Note',
        'Debit_Note_Detail'
    )
ORDER BY TABLE_NAME;

-- ดูว่ามี stored procedure อะไรบ้าง
SELECT
    ROUTINE_NAME,
    ROUTINE_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'dbo'
    AND ROUTINE_NAME LIKE 'sp_%Customer%'
    OR ROUTINE_NAME LIKE 'sp_%CreditNote%'
    OR ROUTINE_NAME LIKE 'sp_%DebitNote%'
    OR ROUTINE_NAME LIKE 'sp_%FrontTeam%'
ORDER BY ROUTINE_NAME;

-- เช็ค columns ใหม่ใน Account_Receipt
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Account_Receipt'
    AND COLUMN_NAME IN (
        'TransactionDate',
        'IsCheckIn',
        'IsFrontTransaction',
        'RevenueCategory',
        'ReferenceDocument'
    )
ORDER BY COLUMN_NAME;
```

---

## ❓ FAQ - คำถามที่พบบ่อย

### Q1: Migration รันไปแล้ว รันอีกครั้งได้ไหม?
**A:** ได้ครับ! แต่ระบบจะ skip ไปอัตโนมัติถ้ารันไปแล้ว (จะเห็นข้อความ "Migration already applied")

### Q2: ถ้า Migration ครึ่งทางแล้ว Error จะเป็นยังไง?
**A:** ระบบมี Transaction protection จะ Rollback อัตโนมัติ ข้อมูลจะไม่เสียหาย

### Q3: ต้อง Migrate ทุก environment หรือไม่?
**A:** ใช่ ต้องรันใน Development, Staging, และ Production แยกกัน

### Q4: ข้อมูลเดิมจะหายไหม?
**A:** **ไม่หายครับ!** Migration นี้เป็นการ**เพิ่ม**เท่านั้น ไม่มีการลบข้อมูลเดิม

### Q5: ใช้เวลานานแค่ไหน?
**A:**
- Migration 07: ~30-60 วินาที
- Migration 08: ~60-120 วินาที
- **รวม: ~2-3 นาที**

---

## 📞 ติดต่อเมื่อมีปัญหา

ถ้ามี error หรือปัญหาใดๆ ให้:
1. **Screenshot error message**
2. **Copy ข้อความ error จาก Messages pane**
3. **บอกว่ากำลังรัน migration ไหน (07 หรือ 08)**
4. **แจ้ง Development Team ทันที**

---

## ✅ Checklist หลัง Migration เสร็จ

- [ ] Backup database เรียบร้อย
- [ ] รัน Migration 00 สำเร็จ
- [ ] รัน Migration 07 สำเร็จ
- [ ] รัน Migration 08 สำเร็จ
- [ ] ตรวจสอบ Database_Migrations table มี 3 records
- [ ] ทดสอบ stored procedures ทำงานได้
- [ ] ตรวจสอบข้อมูลเดิมไม่เสียหาย
- [ ] Build web application สำเร็จ
- [ ] ทดสอบ web application รันได้

---

## 🎉 สิ่งที่ได้หลัง Migration

### ระบบจัดการลูกค้าใหม่:
- ✅ Prevent duplicate customers (email, Tax ID)
- ✅ Audit trail - ติดตามการแก้ไขทั้งหมด
- ✅ Soft delete - ลบแบบปลอดภัย
- ✅ Real-time validation

### ระบบบัญชีมาตรฐาน:
- ✅ ใบลดหนี้ (Credit Note) - สำหรับ refund, ส่วนลด
- ✅ ใบเพิ่มหนี้ (Debit Note) - สำหรับค่าใช้จ่ายเพิ่มเติม
- ✅ Front Team Daily Report - รายงานรายรับประจำวันที่ถูกต้อง
- ✅ Revenue Categorization - จัดหมวดหมู่รายได้
- ✅ รายงานแยกตามช่องทางชำระเงิน

---

**เวอร์ชัน:** 1.0
**อัพเดทล่าสุด:** 3 พฤศจิกายน 2025
**ผู้เขียน:** Development Team
