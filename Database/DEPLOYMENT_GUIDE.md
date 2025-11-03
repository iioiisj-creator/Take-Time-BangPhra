# 🚀 Taketime Database Deployment Guide

## ภาพรวม

เอกสารนี้อธิบายวิธีการ deploy database changes หลังจาก `git pull`

---

## 📋 ขั้นตอนการ Deploy (แนะนำ)

### วิธีที่ 1: ใช้ Batch File (ง่ายที่สุด)

```bash
# 1. Pull code ล่าสุด
git pull

# 2. Double-click ไฟล์นี้
Database/Apply-Migrations.bat
```

**ขั้นตอน:**
1. ใส่ชื่อ SQL Server (default: localhost)
2. ใส่ชื่อ Database (default: Taketime)
3. เลือก Windows Authentication (แนะนำ)
4. รอจนเสร็จ ✅

---

### วิธีที่ 2: ใช้ PowerShell

```powershell
# 1. Pull code ล่าสุด
git pull

# 2. เปิด PowerShell และไปที่โฟลเดอร์ Database
cd "Database"

# 3. รันคำสั่ง (Windows Authentication)
.\Apply-Migrations.ps1

# หรือระบุ server และ database
.\Apply-Migrations.ps1 -ServerName "localhost" -DatabaseName "Taketime"

# หรือใช้ SQL Authentication
.\Apply-Migrations.ps1 -ServerName "localhost" -DatabaseName "Taketime" -UseWindowsAuth:$false -Username "sa" -Password "yourpassword"

# ดูว่าจะมี migration อะไรบ้างโดยไม่รัน
.\Apply-Migrations.ps1 -WhatIf
```

---

### วิธีที่ 3: รันใน SQL Server Management Studio (Manual)

```bash
# 1. Pull code ล่าสุด
git pull

# 2. เปิด SQL Server Management Studio

# 3. รันไฟล์ SQL ตามลำดับ:
```

**ลำดับการรัน:**

1. **ครั้งแรกเท่านั้น:**
   ```sql
   -- รันไฟล์นี้ก่อนทุกอย่าง (ครั้งเดียวพอ)
   Database/00_Init_Migration_System.sql
   ```

2. **ทุกครั้งที่มี migration ใหม่:**
   ```sql
   -- ตรวจสอบว่า migration ไหนรันไปแล้ว
   SELECT * FROM v_MigrationHistory ORDER BY AppliedDate DESC

   -- รันไฟล์ที่ยังไม่ได้รัน (เรียงตามชื่อไฟล์)
   Database/Migration_Add_Extra_Guest_Support.sql
   -- ... ไฟล์อื่นๆ ตามลำดับ
   ```

3. **ตรวจสอบผลลัพธ์:**
   ```sql
   -- ดู migration history
   SELECT * FROM v_MigrationHistory

   -- ตรวจสอบว่าตารางถูกสร้างแล้ว
   SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Accommodation'
   ```

---

## 🔍 ตรวจสอบสถานะ Migration

### ดู Migration ที่รันไปแล้ว:

```sql
SELECT * FROM v_MigrationHistory
ORDER BY AppliedDate DESC
```

### ตรวจสอบว่า Migration เฉพาะรันหรือยัง:

```sql
EXEC sp_IsMigrationApplied 'Migration_Add_Extra_Guest_Support'
-- Result: 1 = รันแล้ว, 0 = ยังไม่รัน
```

---

## 📝 การสร้าง Migration ใหม่

### 1. ตั้งชื่อไฟล์ตามรูปแบบ:

```
[Number]_[Description].sql

ตัวอย่าง:
- 00_Init_Migration_System.sql
- 01_Add_Extra_Guest_Support.sql
- 02_Add_Customer_Email_Validation.sql
- 03_Add_Reservation_Status_Index.sql
```

**กฎการตั้งชื่อ:**
- เริ่มด้วยตัวเลข (2 หลัก) เรียงตามลำดับ
- ตามด้วย underscore (_)
- ชื่อที่อธิบายได้ว่าทำอะไร
- ใช้ .sql extension

---

### 2. Template สำหรับ Migration ใหม่:

```sql
/*==============================================================
  Migration: [ชื่อ Migration]

  Description:
  - [อธิบายว่าทำอะไร]
  - [เปลี่ยนแปลงอะไรบ้าง]

  Author: [ชื่อคนสร้าง]
  Date: [วันที่สร้าง]
==============================================================*/

USE [Taketime]
GO

-- ตรวจสอบว่ารันไปแล้วหรือยัง
DECLARE @MigrationName NVARCHAR(255) = 'ชื่อไฟล์_ไม่รวม_.sql'
DECLARE @IsApplied INT

EXEC sp_IsMigrationApplied @MigrationName, @IsApplied OUTPUT

IF @IsApplied = 1
BEGIN
    PRINT 'Migration already applied: ' + @MigrationName
    RETURN
END
GO

PRINT '============================================================='
PRINT 'Applying Migration: [ชื่อ Migration]'
PRINT '============================================================='
GO

-- ===================================================================
-- เริ่มต้น Transaction
-- ===================================================================
BEGIN TRANSACTION
GO

BEGIN TRY
    -- ===================================================================
    -- [Step 1: ทำอะไร]
    -- ===================================================================
    PRINT 'Step 1: [คำอธิบาย]'

    -- SQL commands here...

    -- ===================================================================
    -- [Step 2: ทำอะไร]
    -- ===================================================================
    PRINT 'Step 2: [คำอธิบาย]'

    -- SQL commands here...

    -- ===================================================================
    -- Commit Transaction
    -- ===================================================================
    COMMIT TRANSACTION

    PRINT ''
    PRINT '✓ Migration completed successfully'
    PRINT ''

    -- บันทึกว่ารัน migration นี้แล้ว
    EXEC sp_RecordMigration
        @MigrationName = '[ชื่อไฟล์_ไม่รวม_.sql]',
        @AppliedBy = SYSTEM_USER,
        @Success = 1

END TRY
BEGIN CATCH
    -- Rollback on error
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
    DECLARE @ErrorState INT = ERROR_STATE()

    PRINT ''
    PRINT '✗ Migration failed'
    PRINT 'Error: ' + @ErrorMessage
    PRINT ''

    -- บันทึกว่ารัน migration นี้แล้วแต่ล้มเหลว
    EXEC sp_RecordMigration
        @MigrationName = '[ชื่อไฟล์_ไม่รวม_.sql]',
        @AppliedBy = SYSTEM_USER,
        @Success = 0,
        @ErrorMessage = @ErrorMessage

    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
END CATCH
GO
```

---

### 3. ตัวอย่าง Migration ที่สมบูรณ์:

```sql
/*==============================================================
  Migration: Add Email Validation

  Description:
  - Add email validation constraint to Customer table
  - Add index on email column for faster lookup

  Author: Developer
  Date: 2025-11-03
==============================================================*/

USE [Taketime]
GO

PRINT '============================================================='
PRINT 'Applying Migration: Add Email Validation'
PRINT '============================================================='
GO

BEGIN TRANSACTION
GO

BEGIN TRY
    -- Add constraint
    IF NOT EXISTS (
        SELECT * FROM sys.check_constraints
        WHERE name = 'CK_Customer_Email_Format'
    )
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD CONSTRAINT [CK_Customer_Email_Format]
        CHECK (Email LIKE '%_@__%.__%')

        PRINT '✓ Added email validation constraint'
    END

    -- Add index
    IF NOT EXISTS (
        SELECT * FROM sys.indexes
        WHERE name = 'IX_Customer_Email'
    )
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Customer_Email]
        ON [dbo].[Customer] ([Email])

        PRINT '✓ Added index on email column'
    END

    COMMIT TRANSACTION

    EXEC sp_RecordMigration
        @MigrationName = 'Add_Email_Validation',
        @AppliedBy = SYSTEM_USER,
        @Success = 1

    PRINT ''
    PRINT '✓ Migration completed successfully'
    PRINT ''

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()

    EXEC sp_RecordMigration
        @MigrationName = 'Add_Email_Validation',
        @AppliedBy = SYSTEM_USER,
        @Success = 0,
        @ErrorMessage = @ErrorMessage

    RAISERROR (@ErrorMessage, 16, 1)
END CATCH
GO
```

---

## ⚠️ Best Practices

### ✅ DO (ทำ):

1. **ตรวจสอบก่อนแก้ไข**
   ```sql
   -- ใช้ IF NOT EXISTS
   IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'NewColumn')
   BEGIN
       ALTER TABLE MyTable ADD NewColumn INT
   END
   ```

2. **ใช้ Transaction**
   ```sql
   BEGIN TRANSACTION
   -- changes here
   COMMIT TRANSACTION
   ```

3. **สำรองข้อมูลก่อน**
   ```sql
   SELECT * INTO Backup_Table_20251103 FROM Original_Table
   ```

4. **ทดสอบใน Development ก่อน**
   - รัน migration ใน dev database ก่อน
   - ตรวจสอบว่าทำงานถูกต้อง
   - แล้วค่อย deploy production

5. **เขียน Rollback Script**
   ```sql
   -- ถ้า migration ผิดพลาด จะ rollback ยังไง?
   ```

---

### ❌ DON'T (อย่าทำ):

1. **❌ แก้ไข Migration ที่รันไปแล้ว**
   - ถ้ารันไปแล้ว ห้ามแก้ไข
   - ให้สร้าง migration ใหม่แทน

2. **❌ ลบข้อมูลโดยไม่สำรอง**
   ```sql
   -- อย่าทำแบบนี้
   DROP TABLE Important_Data

   -- ทำแบบนี้แทน
   SELECT * INTO Backup_Important_Data_20251103 FROM Important_Data
   DROP TABLE Important_Data
   ```

3. **❌ รัน Migration โดยไม่ทดสอบ**
   - ต้องทดสอบก่อนเสมอ

4. **❌ ข้าม Migration**
   - ต้องรันตามลำดับเสมอ

---

## 🔧 Troubleshooting

### ปัญหา: PowerShell execution policy

```powershell
# แก้ไข:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# หรือรันแบบ bypass
powershell.exe -ExecutionPolicy Bypass -File Apply-Migrations.ps1
```

---

### ปัญหา: ไม่สามารถเชื่อมต่อฐานข้อมูล

**ตรวจสอบ:**
1. SQL Server กำลังทำงานอยู่หรือไม่?
2. ชื่อ Server ถูกต้องหรือไม่?
3. Database มีอยู่จริงหรือไม่?
4. User มีสิทธิ์หรือไม่?

```sql
-- ทดสอบการเชื่อมต่อ
SELECT @@SERVERNAME AS ServerName, DB_NAME() AS DatabaseName
```

---

### ปัญหา: Migration ล้มเหลว

```sql
-- 1. ดู error message
SELECT TOP 5 * FROM v_MigrationHistory WHERE Success = 0 ORDER BY AppliedDate DESC

-- 2. แก้ไขปัญหาตาม error message

-- 3. ลบ record ที่ล้มเหลว (ถ้าต้องการรันใหม่)
DELETE FROM Database_Migrations WHERE MigrationName = 'ชื่อ_migration' AND Success = 0

-- 4. รันใหม่
```

---

### ปัญหา: ต้องการ rollback

```sql
-- 1. ดู migration history
SELECT * FROM v_MigrationHistory

-- 2. รัน rollback script ที่เตรียมไว้
-- (อยู่ท้ายไฟล์ migration แต่ละไฟล์)

-- 3. ลบ record ออกจาก migration table
DELETE FROM Database_Migrations WHERE MigrationName = 'ชื่อ_migration'
```

---

## 📊 Migration Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ Developer                                                    │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. Create migration file                                    │
│    - Database/XX_Description.sql                           │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Test in Development                                      │
│    - Run migration                                          │
│    - Verify changes                                         │
│    - Test application                                       │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Commit to Git                                           │
│    git add Database/XX_Description.sql                     │
│    git commit -m "Add migration: Description"              │
│    git push                                                 │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ Other Developers / Production Server                        │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Pull latest code                                        │
│    git pull                                                 │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Apply migrations                                        │
│    Option A: Double-click Apply-Migrations.bat             │
│    Option B: Run .\Apply-Migrations.ps1                    │
│    Option C: Run SQL files in SSMS                         │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Build & Run Application                                │
│    - Migrations auto-applied                               │
│    - Database schema up-to-date                            │
│    - Ready to use                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📞 Support

หากพบปัญหา:

1. ตรวจสอบ error message ใน console
2. ดู migration log: `Database/migration-log.txt`
3. ตรวจสอบ migration history:
   ```sql
   SELECT * FROM v_MigrationHistory ORDER BY AppliedDate DESC
   ```

---

## ✅ Deployment Checklist

### ก่อน Deploy:

- [ ] Pull code ล่าสุด (`git pull`)
- [ ] สำรองฐานข้อมูล
- [ ] อ่าน migration scripts ให้เข้าใจ
- [ ] ทดสอบใน dev environment

### ขณะ Deploy:

- [ ] รัน migration script
- [ ] ตรวจสอบ migration history
- [ ] ทดสอบ application
- [ ] ตรวจสอบ error logs

### หลัง Deploy:

- [ ] ทดสอบฟีเจอร์หลัก
- [ ] ตรวจสอบ performance
- [ ] สำรองฐานข้อมูลอีกครั้ง
- [ ] แจ้งทีมว่า deploy เสร็จแล้ว

---

**Last Updated:** 2025-11-03
