# 🗄️ Taketime Database

Database scripts และ migration system สำหรับโปรเจค Taketime

---

## 🚀 Quick Start

### หลัง git pull ต้องทำอะไร?

**ง่ายๆ แค่ 2 ขั้นตอน:**

```bash
# 1. Pull code ล่าสุด
git pull

# 2. Double-click ไฟล์นี้
Database/Apply-Migrations.bat
```

**เท่านี้เสร็จแล้ว!** ระบบจะ:
- ✅ ตรวจสอบ migration ที่ยังไม่ได้รัน
- ✅ Apply migrations ใหม่โดยอัตโนมัติ
- ✅ บันทึกประวัติการ migration
- ✅ พร้อมใช้งานทันที

---

## 📁 โครงสร้างไฟล์

```
Database/
├── 00_Init_Migration_System.sql          # ⭐ Migration system (รันครั้งแรกเท่านั้น)
├── Migration_Add_Extra_Guest_Support.sql # ตัวอย่าง migration
├── Taketime_Database_Schema.sql          # Full database schema (อ้างอิง)
│
├── Apply-Migrations.bat                  # 🎯 Double-click เพื่อ apply migrations
├── Apply-Migrations.ps1                  # PowerShell script
│
├── DEPLOYMENT_GUIDE.md                   # 📖 คู่มือ deployment แบบละเอียด
├── README_Extra_Guest_Feature.md         # คู่มือฟีเจอร์ผู้พักเสริม
├── TEMPLATE_Migration.sql                # Template สำหรับสร้าง migration ใหม่
└── README.md                             # ⬅️ ไฟล์นี้
```

---

## 📋 วิธีใช้งาน

### สำหรับ Developers

#### 1️⃣ **ครั้งแรก - Setup Migration System**

```bash
# รัน migration system init script (ครั้งเดียวพอ)
# ใน SQL Server Management Studio:
Database/00_Init_Migration_System.sql
```

#### 2️⃣ **ทุกครั้งหลัง git pull**

**วิธีที่ 1: ใช้ Batch File (แนะนำ)**
```bash
# Double-click
Database/Apply-Migrations.bat
```

**วิธีที่ 2: ใช้ PowerShell**
```powershell
cd Database
.\Apply-Migrations.ps1
```

**วิธีที่ 3: รัน SQL ด้วยตนเอง**
```sql
-- 1. ดู migration ที่รันไปแล้ว
SELECT * FROM v_MigrationHistory

-- 2. รันไฟล์ SQL ที่ยังไม่ได้รัน (ตามลำดับ)
```

---

### สำหรับการสร้าง Migration ใหม่

#### 1. Copy Template

```bash
# Copy ไฟล์ template
cp TEMPLATE_Migration.sql 01_Your_Migration_Name.sql
```

#### 2. แก้ไขตาม Template

```sql
/*==============================================================
  Migration: Add Email Validation

  Description:
  - Add email validation constraint
  - Add index for faster lookup

  Author: Your Name
  Created: 2025-11-03
==============================================================*/

-- แก้ไขชื่อ migration
DECLARE @MigrationName NVARCHAR(255) = 'Add_Email_Validation'

-- เขียน SQL ตามต้องการ
ALTER TABLE Customer
ADD CONSTRAINT CK_Customer_Email
CHECK (Email LIKE '%_@__%.__%')

-- บันทึก migration
EXEC sp_RecordMigration
    @MigrationName = 'Add_Email_Validation',
    @AppliedBy = SYSTEM_USER,
    @Success = 1
```

#### 3. Test & Commit

```bash
# Test ใน dev database
.\Apply-Migrations.ps1

# ตรวจสอบว่าทำงานถูกต้อง
# แล้วค่อย commit

git add Database/01_Your_Migration_Name.sql
git commit -m "Add migration: Your Migration Name"
git push
```

---

## 🔍 คำสั่ง SQL ที่มีประโยชน์

### ดู Migration History

```sql
-- ดู migration ทั้งหมด
SELECT * FROM v_MigrationHistory
ORDER BY AppliedDate DESC

-- ดู migration ที่ล้มเหลว
SELECT * FROM v_MigrationHistory
WHERE Success = 0

-- ดู migration ล่าสุด 5 ตัว
SELECT TOP 5 * FROM v_MigrationHistory
ORDER BY AppliedDate DESC
```

### ตรวจสอบ Migration

```sql
-- เช็คว่า migration รันไปแล้วหรือยัง
EXEC sp_IsMigrationApplied 'Migration_Add_Extra_Guest_Support'
-- Result: 1 = รันแล้ว, 0 = ยังไม่รัน
```

### จัดการ Migration

```sql
-- ลบ migration ที่ล้มเหลว (เพื่อรันใหม่)
DELETE FROM Database_Migrations
WHERE MigrationName = 'YourMigration'
AND Success = 0
```

---

## ⚠️ Best Practices

### ✅ DO (ทำ)

1. **รัน migration ตามลำดับ**
   - เรียงตามชื่อไฟล์: 00_, 01_, 02_, ...

2. **ทดสอบก่อนเสมอ**
   - Test ใน dev environment ก่อน production

3. **สำรองข้อมูล**
   - Backup database ก่อน apply migration

4. **ใช้ Transaction**
   - ถ้า migration ล้มเหลว จะ rollback อัตโนมัติ

5. **เขียน Rollback Script**
   - เตรียม script สำหรับ undo migration

### ❌ DON'T (อย่าทำ)

1. **❌ แก้ไข migration ที่รันไปแล้ว**
   - ถ้าต้องการแก้ไข ให้สร้าง migration ใหม่แทน

2. **❌ ข้าม migration**
   - ต้องรันตามลำดับทุกครั้ง

3. **❌ ลบข้อมูลโดยไม่สำรอง**
   - Backup ก่อนทุกครั้ง

4. **❌ Deploy โดยไม่ทดสอบ**
   - Test ก่อนทุกครั้ง

---

## 📚 เอกสารเพิ่มเติม

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - คู่มือ deployment แบบละเอียด
- **[README_Extra_Guest_Feature.md](README_Extra_Guest_Feature.md)** - คู่มือฟีเจอร์ผู้พักเสริม
- **[TEMPLATE_Migration.sql](TEMPLATE_Migration.sql)** - Template สำหรับสร้าง migration

---

## 🔧 Troubleshooting

### ปัญหา: PowerShell execution policy

```powershell
# แก้ไข:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### ปัญหา: Cannot connect to database

ตรวจสอบ:
1. SQL Server กำลังทำงานหรือไม่?
2. ชื่อ server ถูกต้องหรือไม่?
3. Database มีอยู่หรือไม่?
4. User มีสิทธิ์หรือไม่?

### ปัญหา: Migration failed

```sql
-- 1. ดู error message
SELECT * FROM v_MigrationHistory
WHERE Success = 0
ORDER BY AppliedDate DESC

-- 2. แก้ไขปัญหา

-- 3. ลบ record ที่ล้มเหลว
DELETE FROM Database_Migrations
WHERE MigrationName = 'YourMigration'
AND Success = 0

-- 4. รันใหม่
```

---

## 💡 ตัวอย่างการใช้งาน

### Scenario: Pull code มา build แล้ว error

```bash
# 1. Pull code
git pull

# 2. Apply migrations
cd Database
.\Apply-Migrations.bat

# 3. Build project
# ตอนนี้ database schema ตรงกับ code แล้ว

# 4. Run application
# พร้อมใช้งาน!
```

### Scenario: สร้าง feature ใหม่ที่ต้อง alter database

```bash
# 1. สร้าง migration file
cp TEMPLATE_Migration.sql 02_Add_New_Feature.sql

# 2. เขียน SQL
# ... edit file ...

# 3. Test
.\Apply-Migrations.ps1

# 4. Commit
git add Database/02_Add_New_Feature.sql
git commit -m "Add migration for new feature"
git push

# 5. Developer อื่นๆ pull code มา
git pull

# 6. Apply migration
.\Apply-Migrations.bat

# เสร็จ! Database sync ทุกคน
```

---

## ❓ FAQ

**Q: ต้อง apply migration ทุกครั้งหลัง git pull หรือไม่?**

A: ไม่จำเป็น - แต่แนะนำให้รัน เพราะ:
- ถ้าไม่มี migration ใหม่ = ข้าม (ไม่ทำอะไร)
- ถ้ามี migration ใหม่ = apply อัตโนมัติ
- ไม่ต้องเสียเวลาเช็คว่ามีหรือไม่

**Q: Migration รัน 2 ครั้งได้ไหม?**

A: ได้ แต่จะข้าม (skip) - ระบบจำได้ว่า migration ไหนรันไปแล้ว

**Q: ต้องการ rollback migration ทำยังไง?**

A: รัน rollback script ที่อยู่ท้ายไฟล์ migration (comment อยู่)

**Q: สร้าง migration file ใหม่ต้องทำอะไร?**

A: Copy `TEMPLATE_Migration.sql` แล้วแก้ไขตามต้องการ

**Q: ชื่อไฟล์ migration ต้องขึ้นต้นด้วยตัวเลขหรือไม่?**

A: แนะนำให้ขึ้นต้นด้วยตัวเลข (00_, 01_, 02_) เพื่อให้เรียงลำดับได้ง่าย

---

## 📞 Support

หากพบปัญหา:

1. ดู error message ใน console
2. ตรวจสอบ `Database/migration-log.txt`
3. ดู migration history:
   ```sql
   SELECT * FROM v_MigrationHistory
   WHERE Success = 0
   ```
4. อ่าน [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 🎯 Summary

**สำหรับ Developers:**
```bash
git pull
cd Database
.\Apply-Migrations.bat
# เสร็จ!
```

**สำหรับการสร้าง Migration:**
```bash
cp TEMPLATE_Migration.sql XX_New_Migration.sql
# แก้ไขไฟล์
.\Apply-Migrations.ps1
git add && git commit && git push
```

**เท่านี้ก็พร้อมใช้งานแล้ว!** 🎉

---

**Last Updated:** 2025-11-03
