# คู่มือการใช้งาน: ระบบคำนวณผู้เข้าพักเสริมอัตโนมัติ

## 📋 ภาพรวม

ระบบนี้ช่วยให้ Admin ไม่ต้องแก้ไขราคาห้องพักด้วยตนเองเมื่อมีผู้เข้าพักเสริม ระบบจะคำนวณราคาเพิ่มเติมโดยอัตโนมัติตามที่ตั้งค่าไว้

---

## 🎯 ประโยชน์

✅ **ไม่ต้องแก้ไขราคาด้วยตนเอง** - ระบบคำนวณให้อัตโนมัติ
✅ **ลดข้อผิดพลาด** - ราคาถูกต้องตามที่ตั้งค่าเสมอ
✅ **ความยืดหยุ่น** - กำหนดราคาผู้พักเสริมได้แต่ละห้อง
✅ **ไม่กระทบข้อมูลเดิม** - การจองที่ผ่านมาไม่เปลี่ยนแปลง

---

## 🏗️ โครงสร้างข้อมูลใหม่

### ตาราง Accommodation เพิ่ม 3 คอลัมน์:

| คอลัมน์ | ประเภท | คำอธิบาย | ค่าเริ่มต้น |
|---------|--------|----------|-------------|
| **StandardOccupancy** | tinyint | จำนวนผู้เข้าพักมาตรฐาน (ราคาปกติ) | 2 |
| **MaxOccupancy** | tinyint | จำนวนผู้เข้าพักสูงสุด (รวมเสริม) | 2 |
| **ExtraGuestPrice** | smallint | ราคาผู้เข้าพักเสริม/คน/คืน | 0 |

### กฎการตรวจสอบ:

- `StandardOccupancy` > 0 (ต้องมีผู้เข้าพักอย่างน้อย 1 คน)
- `MaxOccupancy` >= `StandardOccupancy` (จำนวนสูงสุดต้องไม่น้อยกว่ามาตรฐาน)
- `ExtraGuestPrice` >= 0 (ราคาต้องไม่ติดลบ)

---

## 📝 วิธีการติดตั้ง

### ขั้นตอนที่ 1: รัน Migration Script

```sql
-- เปิดไฟล์และรันใน SQL Server Management Studio
USE [Taketime]
GO

-- รัน script: Migration_Add_Extra_Guest_Support.sql
-- Script จะสำรองข้อมูลก่อนอัตโนมัติ
```

### ขั้นตอนที่ 2: ตรวจสอบผลลัพธ์

```sql
-- ตรวจสอบว่าคอลัมน์ถูกสร้างแล้ว
SELECT TOP 5
    ID,
    AccomName,
    StandardOccupancy,
    MaxOccupancy,
    Price as BasePrice,
    ExtraGuestPrice,
    Status
FROM Accommodation
ORDER BY ID
```

### ขั้นตอนที่ 3: Deploy โค้ด ASP.NET

1. Build โปรเจค **Take Time BangPhra**
2. Deploy ไฟล์ `Reserve.aspx.cs` ที่อัพเดทแล้ว
3. Restart Application Pool (ถ้าจำเป็น)

---

## ⚙️ การตั้งค่าห้องพัก

### ตัวอย่างที่ 1: บังกะโลมาตรฐาน 2 คน (รับได้สูงสุด 4 คน)

```sql
UPDATE Accommodation
SET
    StandardOccupancy = 2,        -- พักมาตรฐาน 2 คน
    MaxOccupancy = 4,             -- รับได้สูงสุด 4 คน
    ExtraGuestPrice = 200         -- ผู้พักเสริมคนละ 200 บาท/คืน
WHERE AccomName LIKE N'%บังกะโล 2 ท่าน%'
```

**การคำนวณราคา:**

| จำนวนผู้พัก | การคำนวณ | ราคา/คืน |
|-------------|----------|----------|
| 1 คน | 1,000 × 1 | **1,000 บาท** |
| 2 คน (มาตรฐาน) | 1,000 × 2 | **2,000 บาท** |
| 3 คน (+เสริม 1) | (1,000 × 2) + (200 × 1) | **2,200 บาท** |
| 4 คน (+เสริม 2) | (1,000 × 2) + (200 × 2) | **2,400 บาท** |

---

### ตัวอย่างที่ 2: ห้องแฟมิลี่ 4 คน (รับได้สูงสุด 6 คน)

```sql
UPDATE Accommodation
SET
    StandardOccupancy = 4,        -- พักมาตรฐาน 4 คน
    MaxOccupancy = 6,             -- รับได้สูงสุด 6 คน
    ExtraGuestPrice = 300         -- ผู้พักเสริมคนละ 300 บาท/คืน
WHERE AccomName LIKE N'%ห้องแฟมิลี่%'
```

**การคำนวณราคา:**

| จำนวนผู้พัก | การคำนวณ | ราคา/คืน |
|-------------|----------|----------|
| 4 คน (มาตรฐาน) | 2,500 × 4 | **10,000 บาท** |
| 5 คน (+เสริม 1) | (2,500 × 4) + (300 × 1) | **10,300 บาท** |
| 6 คน (+เสริม 2) | (2,500 × 4) + (300 × 2) | **10,600 บาท** |

---

### ตัวอย่างที่ 3: ห้องที่ไม่มีผู้พักเสริม

```sql
UPDATE Accommodation
SET
    StandardOccupancy = 2,        -- พักมาตรฐาน 2 คน
    MaxOccupancy = 2,             -- รับได้สูงสุด 2 คน (ไม่รับเสริม)
    ExtraGuestPrice = 0           -- ไม่มีราคาเสริม
WHERE AccomName LIKE N'%VIP%'
```

---

## 🔄 การทำงานของระบบ

### สูตรการคำนวณ:

```
IF จำนวนผู้พัก <= StandardOccupancy:
    ราคา = BasePrice × จำนวนผู้พัก

ELSE IF จำนวนผู้พัก <= MaxOccupancy:
    ผู้พักเสริม = จำนวนผู้พัก - StandardOccupancy
    ราคา = (BasePrice × StandardOccupancy) + (ผู้พักเสริม × ExtraGuestPrice)

ELSE:
    แจ้งเตือน: เกินจำนวนที่รองรับ
```

### ตัวอย่างการใช้งานจริง:

**สถานการณ์:** ลูกค้าจอง "บังกะโล 2 ท่าน" 3 คน 2 คืน

**ข้อมูลห้อง:**
- StandardOccupancy: 2 คน
- MaxOccupancy: 4 คน
- BasePrice: 1,000 บาท/คน/คืน
- ExtraGuestPrice: 200 บาท/คน/คืน

**การคำนวณ:**
```
ผู้พักเสริม = 3 - 2 = 1 คน
ราคาต่อคืน = (1,000 × 2) + (200 × 1) = 2,200 บาท
รวม 2 คืน = 2,200 × 2 = 4,400 บาท
```

**ก่อนใช้ระบบใหม่:**
❌ Admin ต้องคำนวณเอง และแก้ไขราคาใน UI
❌ ถ้าคำนวณผิด = ราคาผิด

**หลังใช้ระบบใหม่:**
✅ ระบบคำนวณให้อัตโนมัติ
✅ ราคาถูกต้องเสมอ

---

## 📊 ตัวอย่าง SQL Query

### ดูรายการห้องทั้งหมดพร้อมการตั้งค่า:

```sql
SELECT
    ID,
    AccomName as [ชื่อห้อง],
    StandardOccupancy as [ผู้พักมาตรฐาน],
    MaxOccupancy as [รับได้สูงสุด],
    Price as [ราคาพื้นฐาน],
    ExtraGuestPrice as [ราคาผู้พักเสริม],
    CASE
        WHEN LimitWithPeople = 1 THEN N'คิดตามคน'
        ELSE N'คิดต่อห้อง'
    END as [ประเภท],
    Status as [สถานะ]
FROM Accommodation
WHERE Status = 1
ORDER BY OrderID
```

### Update ราคาผู้พักเสริมทีเดียวหลายห้อง:

```sql
-- ตั้งค่าผู้พักเสริมสำหรับห้องบังกะโลทุกห้อง
UPDATE Accommodation
SET
    StandardOccupancy = 2,
    MaxOccupancy = 4,
    ExtraGuestPrice = 200
WHERE AccomName LIKE N'%บังกะโล%'
  AND Status = 1
```

### ตรวจสอบการจองที่มีผู้พักเกิน:

```sql
SELECT
    R.ID as [เลขที่จอง],
    C.Name as [ชื่อลูกค้า],
    A.AccomName as [ห้อง],
    A.StandardOccupancy as [พักมาตรฐาน],
    RA.Amount as [จำนวนผู้พักจริง],
    CASE
        WHEN RA.Amount > A.StandardOccupancy
        THEN RA.Amount - A.StandardOccupancy
        ELSE 0
    END as [ผู้พักเสริม],
    RA.Price as [ราคาที่บันทึก]
FROM Reservation R
INNER JOIN Customer C ON R.Customer_MobilePhone = C.MobilePhone
INNER JOIN Reservation_Accommodation RA ON R.ID = RA.Reservation_ID
INNER JOIN Accommodation A ON RA.Accommodation_ID = A.ID
WHERE R.CheckinDate >= '2025-01-01'
  AND RA.Amount > A.StandardOccupancy
ORDER BY R.CheckinDate DESC
```

---

## 🔍 การตรวจสอบและแก้ไขปัญหา

### ปัญหา 1: ราคายังไม่ถูกต้อง

**สาเหตุ:**
- ยังไม่ได้ตั้งค่า StandardOccupancy, MaxOccupancy, ExtraGuestPrice

**วิธีแก้:**
```sql
-- ตรวจสอบค่าว่างหรือไม่ถูกต้อง
SELECT * FROM Accommodation
WHERE ExtraGuestPrice IS NULL
   OR StandardOccupancy = 0
   OR MaxOccupancy < StandardOccupancy
```

---

### ปัญหา 2: ข้อมูลเดิมเปลี่ยนแปลง

**สาเหตุ:**
- ไม่ควรเกิด เพราะ migration จะไม่แก้ไข Reservation_Accommodation

**วิธีตรวจสอบ:**
```sql
-- เปรียบเทียบกับข้อมูลสำรอง
SELECT * FROM Accommodation_Backup_20251103
EXCEPT
SELECT * FROM Accommodation
```

---

### ปัญหา 3: ต้องการยกเลิกการใช้งาน

**วิธี Rollback:**
```sql
-- Uncomment และรัน rollback script ที่ท้าย Migration_Add_Extra_Guest_Support.sql
-- หรือ restore จาก backup:

-- 1. Drop constraints
ALTER TABLE Accommodation DROP CONSTRAINT IF EXISTS CK_Accommodation_MaxOccupancy
ALTER TABLE Accommodation DROP CONSTRAINT IF EXISTS CK_Accommodation_StandardOccupancy
ALTER TABLE Accommodation DROP CONSTRAINT IF EXISTS CK_Accommodation_ExtraGuestPrice
ALTER TABLE Accommodation DROP CONSTRAINT IF EXISTS DF_Accommodation_StandardOccupancy
ALTER TABLE Accommodation DROP CONSTRAINT IF EXISTS DF_Accommodation_MaxOccupancy
ALTER TABLE Accommodation DROP CONSTRAINT IF EXISTS DF_Accommodation_ExtraGuestPrice

-- 2. Drop columns
ALTER TABLE Accommodation DROP COLUMN StandardOccupancy
ALTER TABLE Accommodation DROP COLUMN MaxOccupancy
ALTER TABLE Accommodation DROP COLUMN ExtraGuestPrice
```

---

## 📞 การติดต่อและสนับสนุน

หากพบปัญหาหรือต้องการความช่วยเหลือ:

1. ตรวจสอบ Log ในตาราง `Logs`:
   ```sql
   SELECT TOP 50 *
   FROM Logs
   WHERE LogAction LIKE '%Extra Guest%'
      OR LogAction LIKE '%Accommodation%'
   ORDER BY LogDateTime DESC
   ```

2. สำรองข้อมูลก่อนทดสอบเสมอ
3. ทดสอบกับห้องทดสอบก่อนนำไปใช้จริง

---

## ✅ Checklist การ Deploy

- [ ] สำรองฐานข้อมูล Taketime
- [ ] รัน Migration_Add_Extra_Guest_Support.sql
- [ ] ตรวจสอบคอลัมน์ใหม่ถูกสร้าง
- [ ] ตั้งค่า StandardOccupancy, MaxOccupancy, ExtraGuestPrice สำหรับห้องที่ต้องการ
- [ ] Deploy Reserve.aspx.cs ใหม่
- [ ] Restart IIS Application Pool
- [ ] ทดสอบการจองห้องกับข้อมูลทดสอบ
- [ ] ตรวจสอบการคำนวณราคา
- [ ] ทดสอบกับ Rate Plan ต่างๆ
- [ ] ทดสอบกับ Voucher/Affiliate Discount
- [ ] Backup หลัง Deploy สำเร็จ

---

## 📅 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-03 | Initial release - Extra guest support |

---

## 🎓 ตัวอย่างการใช้งานขั้นสูง

### Scenario 1: โปรโมชันช่วงวันหยุด

```sql
-- ตั้งราคาผู้พักเสริมพิเศษในช่วงไฮซีซั่น
UPDATE Accommodation
SET ExtraGuestPrice = 300  -- เพิ่มจาก 200 เป็น 300
WHERE AccomName LIKE N'%บังกะโล%'

-- หลังช่วงโปรโมชันเปลี่ยนกลับ
UPDATE Accommodation
SET ExtraGuestPrice = 200
WHERE AccomName LIKE N'%บังกะโล%'
```

### Scenario 2: กำหนดห้องพิเศษ

```sql
-- ห้อง VIP ไม่รับผู้พักเสริม
UPDATE Accommodation
SET
    StandardOccupancy = 2,
    MaxOccupancy = 2,
    ExtraGuestPrice = 0
WHERE AccomName LIKE N'%VIP%'

-- ห้องกลุ่ม รับได้มาก
UPDATE Accommodation
SET
    StandardOccupancy = 6,
    MaxOccupancy = 10,
    ExtraGuestPrice = 150
WHERE AccomName LIKE N'%กลุ่ม%'
```

---

**หมายเหตุ:** เอกสารนี้จะอัพเดทตามการพัฒนาระบบ กรุณาตรวจสอบเวอร์ชันล่าสุดเสมอ
