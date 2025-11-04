# การปรับปรุงระบบตรวจสอบคูปองและส่วนลด
# Coupon Validation System Improvements

## สรุปการเปลี่ยนแปลง (Summary of Changes)

วันที่อัพเดท: 2025-11-04

### ✅ ปัญหาที่แก้ไข (Problems Fixed)

1. **ข้อความแสดงข้อผิดพลาดไม่ชัดเจน**
   - เดิม: แสดงข้อความเดียวกันทุกกรณี "รหัสไม่ถูกต้อง กรุณาใส่ตัวเล็ก ตัวใหญ่ให้ถูกต้อง"
   - ใหม่: แสดงข้อความที่ระบุปัญหาชัดเจนสำหรับแต่ละกรณี

2. **ไม่มีการตรวจสอบรูปแบบรหัสคูปอง**
   - เดิม: ถ้ารหัสไม่ใช่ 8 หรือ 13 ตัว จะไม่แสดงข้อความใดๆ
   - ใหม่: แสดงข้อความบอกรูปแบบที่ถูกต้อง

3. **ไม่มีระบบ Logging**
   - เดิม: ไม่สามารถติดตามการใช้งานคูปองได้
   - ใหม่: บันทึกทุกครั้งที่มีการตรวจสอบคูปอง

---

## 🎯 ฟีเจอร์ใหม่ (New Features)

### 1. ข้อความแสดงข้อผิดพลาดที่ชัดเจนกว่า

#### Affiliate Code (8 ตัวอักษร):
- ❌ **ไม่พบรหัส**: แสดงคำแนะนำในการตรวจสอบ
- ✅ **สำเร็จ**: แจ้งให้เลือกห้องพักใหม่

#### Voucher Code (13 ตัวอักษร ขึ้นต้นด้วย v/V):
- ❌ **ยังไม่เลือกวันที่**: บอกให้เลือกวันที่ Check-In ก่อน
- ❌ **Voucher ถูกใช้ไปแล้ว**: แจ้งชัดเจนว่าถูกใช้งานแล้ว
- ❌ **Voucher หมดอายุ**: แสดงวันหมดอายุและวันที่เลือก
- ❌ **ไม่สามารถใช้กับห้องที่เลือก**: บอกว่า Voucher ไม่รองรับประเภทห้องนี้
- ❌ **ไม่พบ Voucher**: แสดงคำแนะนำในการตรวจสอบ
- ✅ **สำเร็จ**: แจ้งให้เลือกห้องพักใหม่

#### รูปแบบไม่ถูกต้อง:
- แสดงรูปแบบที่ถูกต้องของทั้ง 2 ประเภท
- แสดงจำนวนตัวอักษรที่ใส่เข้ามา

### 2. ระบบ Logging

**ตำแหน่งไฟล์**: `~/Logs/CouponValidation.log`

**ข้อมูลที่บันทึก**:
- วันเวลาที่ตรวจสอบ
- รหัสคูปองที่ใช้
- ประเภทคูปอง (Affiliate/Voucher)
- เบอร์โทรศัพท์ผู้จอง
- วันที่ Check-In
- ผลการตรวจสอบ (สำเร็จ/ล้มเหลว/สาเหตุ)

**ตัวอย่าง Log**:
```
[2025-11-04 14:30:45] Coupon: TEST1234 | Type: Affiliate | Phone: 0812345678 | Check-in: 2025-11-10 | Result: FAILED - Code not found
[2025-11-04 14:32:10] Coupon: V1234567890AB | Type: Voucher | Phone: 0812345678 | Check-in: 2025-11-10 | Result: SUCCESS - Voucher applied
[2025-11-04 14:35:20] Coupon: V1234567890AB | Type: Voucher | Phone: 0898765432 | Check-in: 2025-12-01 | Result: FAILED - Already used
```

### 3. การตรวจสอบที่ดีขึ้น

- **Trim whitespace**: ตัดช่องว่างหน้า-หลังรหัสคูปองอัตโนมัติ
- **Empty validation**: ตรวจสอบว่าใส่รหัสหรือยัง
- **Date validation**: ตรวจสอบว่าเลือกวันที่สำหรับ Voucher หรือยัง
- **Better error handling**: จัดการ Exception ได้ดีขึ้น พร้อมแสดงข้อความ error

---

## 📋 วิธีใช้งาน (How to Use)

### สำหรับผู้ใช้งาน (Users):

1. **เลือกวันที่ Check-In ก่อน** (สำหรับ Voucher)
2. ใส่รหัสคูปองในช่อง "รหัสส่วนลด"
   - Affiliate: 8 ตัวอักษร
   - Voucher: 13 ตัวอักษร ขึ้นต้นด้วย v หรือ V
3. กดปุ่ม "Submit"
4. ถ้าสำเร็จ: เลือกห้องพักใหม่เพื่อรับส่วนลด
5. ถ้าล้มเหลว: อ่านข้อความแจ้งเตือนและแก้ไข

### สำหรับ Admin/Developer:

**ดู Log การใช้งานคูปอง**:
```bash
# ดู log ล่าสุด
tail -n 50 "Take Time BangPhra/Logs/CouponValidation.log"

# ค้นหาคูปองเฉพาะ
grep "V1234567890AB" "Take Time BangPhra/Logs/CouponValidation.log"

# ดูคูปองที่ล้มเหลว
grep "FAILED" "Take Time BangPhra/Logs/CouponValidation.log"

# ดูคูปองที่สำเร็จ
grep "SUCCESS" "Take Time BangPhra/Logs/CouponValidation.log"
```

---

## 🔧 Technical Details

### ไฟล์ที่แก้ไข (Modified Files):

1. **Reserve.aspx.cs**
   - Function: `Button8_Click()` (line 4446-4593)
   - New Function: `LogCouponAttempt()` (line 4595-4616)

2. **Logs/** (ใหม่)
   - Directory สำหรับเก็บ log files

### Dependencies:

- `System.IO` - สำหรับการเขียน log file
- `Server.MapPath()` - สำหรับหาตำแหน่งไฟล์
- Existing: `code.DatabaseQuery()`, `code2.ParseDate()`

---

## 🐛 การแก้ไขปัญหา (Troubleshooting)

### ปัญหา: Log file ไม่ถูกสร้าง
**แก้ไข**:
- ตรวจสอบว่าโฟลเดอร์ `Logs/` มีสิทธิ์ในการเขียนไฟล์
- บน IIS: ให้สิทธิ์ `IIS_IUSRS` ในการเขียนโฟลเดอร์นี้

```bash
# Windows Command (Run as Administrator)
icacls "Take Time BangPhra\Logs" /grant "IIS_IUSRS:(OI)(CI)F"
```

### ปัญหา: ข้อความแสดงผลไม่ถูกต้อง
**แก้ไข**:
- ตรวจสอบ encoding ของหน้าเว็บเป็น UTF-8
- ใน `web.config`:
```xml
<globalization culture="th-TH" uiCulture="th-TH" fileEncoding="utf-8" />
```

---

## 📊 ตัวอย่างข้อความที่แสดง (Example Messages)

### สำเร็จ (Success):
```
✅ ใช้รหัส Affiliate สำเร็จ!

กรุณาเลือกห้องพักอีกครั้ง ระบบได้ปรับราคาตามส่วนลดเรียบร้อยแล้ว
```

### ล้มเหลว (Failure):
```
❌ ไม่พบรหัส Affiliate นี้ในระบบ

กรุณาตรวจสอบว่า:
- พิมพ์ถูกต้อง (ตัวพิมพ์เล็ก/ใหญ่)
- รหัสมี 8 ตัวอักษร
- รหัสยังใช้งานได้

Affiliate code not found. Please check the code and try again.
```

```
❌ Voucher นี้หมดอายุแล้ว

วันหมดอายุ: 31/10/2025
วันที่เลือก Check-Out: 10/11/2025

Voucher has expired.
```

---

## 🔐 Security Notes

⚠️ **TODO**: ยังคงมีช่องโหว่ SQL Injection ในโค้ดเดิม
- ควรเปลี่ยนจาก string concatenation เป็น parameterized queries
- ตัวอย่าง:
```csharp
// แนะนำให้แก้ไขในอนาคต
var cmd = new SqlCommand("SELECT * FROM Affiliate_Member WHERE Coupon_Code = @code");
cmd.Parameters.AddWithValue("@code", couponCode);
```

---

## 📝 Version History

- **v2.0** (2025-11-04):
  - ✅ Improved error messages
  - ✅ Added logging system
  - ✅ Better validation
  - ✅ Enhanced user experience

- **v1.0** (Before):
  - Basic coupon validation
  - Generic error messages
  - No logging

---

## 👤 Contact

หากพบปัญหาหรือต้องการความช่วยเหลือ:
- ติดต่อทีม IT Support
- หรือเปิด Issue ใน repository นี้
