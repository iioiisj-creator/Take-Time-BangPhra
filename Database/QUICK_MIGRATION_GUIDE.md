# คู่มือรัน Database Migrations ฉบับย่อ

## ⚠️ สำคัญ: ต้องรันตามลำดับนี้เท่านั้น!

```
Step 0: Clean Data (ถ้ามี MobilePhone ซ้ำ)
   ↓
Step 1: Migration 07 (Customer Management)
   ↓
Step 2: Migration 08 (Accounting System)
```

---

## 🔍 Step 0: ตรวจสอบข้อมูลซ้ำก่อน

### เปิด SQL Server Management Studio แล้วรันคำสั่งนี้:

```sql
USE [Taketime]
GO

-- ตรวจสอบว่ามี MobilePhone ซ้ำไหม
SELECT MobilePhone, COUNT(*) AS จำนวนซ้ำ
FROM Customer
WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
GROUP BY MobilePhone
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC
```

### ผลลัพธ์:

#### ✅ กรณีที่ 1: ไม่มีผลลัพธ์ (No results)
```
ไม่มีข้อมูลซ้ำ → ข้ามไป Step 1 เลย
```

#### ❌ กรณีที่ 2: มีผลลัพธ์แสดง (มีเบอร์ซ้ำ)
```
MobilePhone    จำนวนซ้ำ
-------------- ---------
0812345678     3
0898765432     2
```

**ต้องแก้ไขก่อน!** รัน Script ทำความสะอาดข้อมูล:

### วิธีที่ 1: ใช้ Script อัตโนมัติ (แนะนำ)

```sql
-- เปิดไฟล์นี้ใน SSMS แล้วกด Execute (F5)
Database/00_Apply_Fix_Duplicate_MobilePhone.sql
```

Script จะ:
- ลบ Customer ที่เบอร์ว่างและไม่มี Reservation
- อัปเดต Customer ที่เบอร์ว่างแต่มี Reservation → `UNKNOWN_[ID]`
- เปลี่ยนชื่อเบอร์ซ้ำ → `DUP_[ID]_[เบอร์เดิม]`

### วิธีที่ 2: ทำเอง (Manual)

```sql
-- เปิดไฟล์นี้ และ Copy-Paste ทีละคำสั่ง
Database/CLEAN_CUSTOMER_DATA.sql
```

---

## 📝 Step 1: รัน Migration 07 - Customer Management

### เปิดไฟล์นี้ใน SSMS:
```
Database/07_Add_Customer_Management_Enhancement.sql
```

### กด Execute (F5)

### ผลลัพธ์ที่ต้องเห็น:

```sql
=============================================================
Migration: 07_Add_Customer_Management_Enhancement
Started: 2025-11-04 ...
=============================================================

Running pre-flight checks...
✓ Customer table exists
✓ Admin table exists

Starting database modifications...

Step 1: Creating Customer_Audit_Log table...
  ✓ Created Customer_Audit_Log table

Step 2: Ensuring Customer.MobilePhone is unique...
  ✓ Created unique constraint on Customer.MobilePhone

Step 3: Adding foreign key constraints...
  ✓ Created FK_Customer_Audit_Log_Customer
  ✓ Created FK_Customer_Audit_Log_Admin

...

✓ Migration completed successfully
```

### ❌ ถ้าเจอ Error:

**Error:** `Duplicate MobilePhone values found`
- **แก้ไข:** กลับไปทำ Step 0 ให้เสร็จก่อน

**Error:** `CREATE UNIQUE INDEX terminated because duplicate key found`
- **แก้ไข:** กลับไปทำ Step 0 ให้เสร็จก่อน

**Error:** `Could not create constraint or index`
- **แก้ไข:** กลับไปทำ Step 0 ให้เสร็จก่อน

---

## 💰 Step 2: รัน Migration 08 - Accounting System

### เปิดไฟล์นี้ใน SSMS:
```
Database/08_Add_Standard_Accounting_System.sql
```

### กด Execute (F5)

### ผลลัพธ์ที่ต้องเห็น:

```sql
=============================================================
Migration: 08_Add_Standard_Accounting_System
Started: 2025-11-04 ...
=============================================================

Running pre-flight checks...
✓ Customer table exists
✓ Reservation table exists
✓ Account_Receipt table exists

Step 1: Adding new columns to Account_Receipt...
  ✓ Added RevenueCategory column
  ✓ Added PaymentChannel column
  ...

Step 2: Creating indexes...
  ✓ Created IX_Account_Receipt_RevenueCategory
  ✓ Created IX_Account_Receipt_PaymentChannel
  ...

✓ Migration completed successfully
```

### ❌ ถ้าเจอ Error:

**Error:** `Incorrect syntax near 'ACCOMMODATION'`
- **แก้ไข:** Pull โค้ดล่าสุดจาก Git (ได้แก้ไขแล้ว)
- คำสั่ง: `git pull origin claude/create-taketime-database-011CUkLZUbuJ3mg2G17MacRS`

---

## ✅ ตรวจสอบว่า Migrations สำเร็จ

รันคำสั่งนี้:

```sql
USE [Taketime]
GO

SELECT
    MigrationName,
    Success,
    Applied_Date,
    Duration_Seconds
FROM Database_Migrations
WHERE MigrationName IN (
    '07_Add_Customer_Management_Enhancement',
    '08_Add_Standard_Accounting_System'
)
ORDER BY Applied_Date DESC
```

### ผลลัพธ์ที่ต้องเห็น:

```
MigrationName                              Success  Applied_Date              Duration_Seconds
------------------------------------------ -------- ------------------------- ----------------
08_Add_Standard_Accounting_System          1        2025-11-04 14:30:15       2.456
07_Add_Customer_Management_Enhancement     1        2025-11-04 14:28:10       1.234
```

ทั้ง 2 migrations ต้องมี `Success = 1` ✅

---

## 🆘 ถ้ายังติดปัญหา

ส่งข้อมูลเหล่านี้มา:

1. **Error message เต็ม ๆ จาก SSMS**
2. **ผลลัพธ์จากคำสั่ง:**
   ```sql
   SELECT MobilePhone, COUNT(*) FROM Customer
   WHERE MobilePhone IS NOT NULL AND MobilePhone != ''
   GROUP BY MobilePhone HAVING COUNT(*) > 1
   ```
3. **ผลลัพธ์จาก:**
   ```sql
   SELECT * FROM Database_Migrations
   ORDER BY Applied_Date DESC
   ```

---

## 📊 Features ที่จะได้หลังจาก Migrate

### Migration 07 เพิ่ม:
- ✅ Customer Audit Log (ติดตามการแก้ไขข้อมูลลูกค้า)
- ✅ Unique constraint บน MobilePhone (ไม่มีเบอร์ซ้ำ)
- ✅ Stored procedures สำหรับ Upsert Customer
- ✅ Indexes เพิ่มความเร็วการค้นหา

### Migration 08 เพิ่ม:
- ✅ Revenue Category (ACCOMMODATION, FOOD_BEVERAGE, RENTAL, OTHER)
- ✅ Payment Channel tracking (เงินสด, โอน, บัตร)
- ✅ Accounting reports โดย Category และ Payment Channel
- ✅ Excel export ในหน้า CheckDocument.aspx

---

## 🎯 สรุป

```bash
# 1. ตรวจสอบข้อมูลซ้ำ
SELECT MobilePhone, COUNT(*) FROM Customer ...

# 2. ถ้ามีซ้ำ → รัน cleanup
00_Apply_Fix_Duplicate_MobilePhone.sql

# 3. รัน Migration 07
07_Add_Customer_Management_Enhancement.sql

# 4. รัน Migration 08
08_Add_Standard_Accounting_System.sql

# 5. ตรวจสอบความสำเร็จ
SELECT * FROM Database_Migrations
```

เสร็จแล้ว! 🎉
