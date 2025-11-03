# 🏨 Taketime PMS Upgrade Roadmap

## ภาพรวมโปรเจค

ปรับปรุงระบบจากการจองธรรมดา เป็น **Property Management System (PMS)** แบบเต็มรูปแบบ

---

## 🎯 ฟีเจอร์ที่ต้องพัฒนา

### 1. 🍖 Product Gallery in Reservation (หมูกระทะ, set ไวน์)

**ความต้องการ:**
- แสดง Product บางประเภทเป็นรูปภาพในหน้าจอง
- เลื่อนดูรูปได้ (carousel/slider)
- เลือกจากรูปได้
- เพิ่มจำนวนได้

**Database Changes:**
- เพิ่มตาราง `Product_Images` - เก็บรูปภาพ product
- เพิ่ม `ShowInReservation` flag ใน `Product` table
- เพิ่ม `DisplayOrder` สำหรับเรียงลำดับ

**UI Components:**
- Product image carousel/grid
- Image modal/lightbox
- Quantity selector
- Add to cart functionality

---

### 2. 🏨 PMS Features (Check-in/Check-out + Folio)

#### 2.1 Guest Folio System (บิลห้อง)

**ความต้องการ:**
- ซื้อของสามารถลงบิลห้องได้
- รวบรวมค่าใช้จ่ายทั้งหมดของห้อง
- แสดงยอดคงค้าง

**Database Changes:**
- ตาราง `Guest_Folio` - บิลห้องพัก
- ตาราง `Folio_Transaction` - รายการในบิล
- ตาราง `Folio_Payment` - การชำระเงิน

**Features:**
- Post charges to room
- View guest folio
- Split folio (แยกบิล)
- Settlement (ชำระเงิน)

#### 2.2 Check-in/Check-out Process

**ความต้องการ:**
- กระบวนการเช็คอินที่เป็นระบบ
- ตรวจสอบยอดคงค้างก่อนเช็คเอาท์
- ถ้ามีค้าง = เช็คเอาท์ไม่ได้

**Database Changes:**
- เพิ่ม `ActualCheckInDate`, `ActualCheckOutDate` ใน `Reservation`
- ตาราง `Room_Status` - สถานะห้อง realtime
- ตาราง `Housekeeping_Status` - สถานะความสะอาด

**Workflow:**
```
Check-In:
1. เลือก reservation
2. ตรวจสอบข้อมูลผู้เข้าพัก
3. Collect ID/Passport
4. Create guest folio
5. Mark as checked-in

Check-Out:
1. เลือก reservation
2. ตรวจสอบยอดคงค้าง
3. ถ้ามียอดค้าง → ชำระก่อน
4. ถ้าไม่มียอดค้าง → อนุญาตเช็คเอาท์
5. Print final bill
6. Mark as checked-out
```

---

### 3. 📎 Payment Slip Upload System

**ความต้องการ:**
- ทุกยอดที่รับเงินต้องมีให้แนบสลิป
- แยกทุกยอด
- ไม่บังคับ ยกเว้นหน้าการจองครั้งแรก (required)

**Database Changes:**
- ตาราง `Payment_Slips` - เก็บรูปสลิป
  - PaymentID, FileName, FilePath, UploadDate

**Features:**
- Upload image (JPEG, PNG)
- Preview slip
- Download/View slip
- Required validation on first reservation

---

### 4. 🎨 Responsive Design Upgrade

**ความต้องการ:**
- Design ที่สมส่วน
- เป็นทางการ
- Responsive (Desktop, Tablet, Mobile)

**Framework/Libraries:**
- Bootstrap 5 / Tailwind CSS
- CSS Grid & Flexbox
- Mobile-first approach

**Components:**
- Navigation bar
- Cards for products/rooms
- Forms (responsive)
- Tables (responsive)
- Modals
- Image galleries

---

## 📊 Database Schema Changes

### New Tables:

#### 1. Product_Images
```sql
CREATE TABLE Product_Images (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Product_ID INT NOT NULL,
    ImagePath NVARCHAR(500) NOT NULL,
    DisplayOrder TINYINT DEFAULT 0,
    IsDefault BIT DEFAULT 0,
    Status BIT DEFAULT 1,
    FOREIGN KEY (Product_ID) REFERENCES Product(ID)
)
```

#### 2. Guest_Folio
```sql
CREATE TABLE Guest_Folio (
    ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Reservation_ID BIGINT NOT NULL,
    FolioNumber NVARCHAR(20) NOT NULL UNIQUE,
    Created_Date DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'OPEN', -- OPEN, CLOSED, SPLIT
    TotalCharges DECIMAL(18,2) DEFAULT 0,
    TotalPayments DECIMAL(18,2) DEFAULT 0,
    Balance AS (TotalCharges - TotalPayments) PERSISTED,
    FOREIGN KEY (Reservation_ID) REFERENCES Reservation(ID)
)
```

#### 3. Folio_Transaction
```sql
CREATE TABLE Folio_Transaction (
    ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Folio_ID BIGINT NOT NULL,
    TransactionDate DATETIME DEFAULT GETDATE(),
    TransactionType NVARCHAR(20) NOT NULL, -- CHARGE, PAYMENT, ADJUSTMENT
    ProductType_ID TINYINT,
    Product_ID INT,
    Description NVARCHAR(500) NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    Quantity DECIMAL(10,2) DEFAULT 1,
    Reference_Number NVARCHAR(50),
    Created_By_ID SMALLINT,
    FOREIGN KEY (Folio_ID) REFERENCES Guest_Folio(ID)
)
```

#### 4. Payment_Slips
```sql
CREATE TABLE Payment_Slips (
    ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Payment_Type NVARCHAR(20) NOT NULL, -- DEPOSIT, PAYMENT, SETTLEMENT
    Reference_ID NVARCHAR(50) NOT NULL, -- Reservation_ID, Receipt_ID, etc.
    FileName NVARCHAR(255) NOT NULL,
    FilePath NVARCHAR(500) NOT NULL,
    FileSize BIGINT,
    UploadDate DATETIME DEFAULT GETDATE(),
    UploadedBy_ID SMALLINT,
    Status BIT DEFAULT 1
)
```

#### 5. Room_Status
```sql
CREATE TABLE Room_Status (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Accommodation_ID TINYINT NOT NULL,
    StatusDate DATE DEFAULT CAST(GETDATE() AS DATE),
    Occupancy_Status NVARCHAR(20) DEFAULT 'VACANT', -- VACANT, OCCUPIED, RESERVED
    Housekeeping_Status NVARCHAR(20) DEFAULT 'CLEAN', -- CLEAN, DIRTY, INSPECTED
    Out_Of_Order BIT DEFAULT 0,
    FOREIGN KEY (Accommodation_ID) REFERENCES Accommodation(ID),
    UNIQUE (Accommodation_ID, StatusDate)
)
```

### Modified Tables:

#### Reservation
```sql
ALTER TABLE Reservation ADD
    ActualCheckInDate DATETIME NULL,
    ActualCheckInBy_ID SMALLINT NULL,
    ActualCheckOutDate DATETIME NULL,
    ActualCheckOutBy_ID SMALLINT NULL,
    Folio_ID BIGINT NULL,
    HasOutstandingBalance BIT DEFAULT 0
```

#### Product
```sql
ALTER TABLE Product ADD
    ShowInReservation BIT DEFAULT 0,
    DisplayOrder TINYINT DEFAULT 0,
    HasImages BIT DEFAULT 0
```

---

## 🗺️ Development Phases

### Phase 1: Database & Backend (Week 1-2)

**Priority: HIGH**

✅ Tasks:
1. Create database migration scripts
2. Update `Reservation` table
3. Create `Guest_Folio` tables
4. Create `Payment_Slips` table
5. Create `Product_Images` table
6. Create `Room_Status` table
7. Write stored procedures for folio management
8. Write check-in/check-out logic

📁 Files:
- `Database/03_Add_PMS_Features.sql`
- `Database/04_Add_Product_Images.sql`
- `Database/05_Add_Payment_Slips.sql`

---

### Phase 2: Product Gallery (Week 2)

**Priority: HIGH**

✅ Tasks:
1. Create product image upload interface
2. Build image carousel component
3. Integrate with reservation page
4. Add to reservation cart

📁 Files:
- `Take Time BangPhra/Admin/Product_Images.aspx` (upload)
- `Take Time BangPhra/Components/ProductGallery.ascx`
- Update `Reserve.aspx` with gallery

---

### Phase 3: Guest Folio System (Week 3)

**Priority: HIGH**

✅ Tasks:
1. Create folio management page
2. Post charges to room
3. View guest folio
4. Settlement process
5. Print folio

📁 Files:
- `Take Time BangPhra/PMS/GuestFolio.aspx`
- `Take Time BangPhra/PMS/PostCharge.aspx`
- `Take Time BangPhra/Class/FolioService.cs`

---

### Phase 4: Check-in/Check-out (Week 3-4)

**Priority: HIGH**

✅ Tasks:
1. Check-in process page
2. Check-out process page
3. Outstanding balance validation
4. Room status management
5. Integration with folio

📁 Files:
- `Take Time BangPhra/PMS/CheckIn.aspx`
- `Take Time BangPhra/PMS/CheckOut.aspx`
- `Take Time BangPhra/Class/CheckInOutService.cs`

---

### Phase 5: Payment Slip Upload (Week 4)

**Priority: MEDIUM**

✅ Tasks:
1. File upload component
2. Image preview
3. Storage management
4. Validation (required on first booking)
5. View/download slips

📁 Files:
- `Take Time BangPhra/Components/PaymentSlipUpload.ascx`
- `Take Time BangPhra/Class/FileUploadService.cs`
- Update `Reserve.aspx`, `Account/Receipt.aspx`

---

### Phase 6: Responsive Design (Week 5-6)

**Priority: MEDIUM**

✅ Tasks:
1. Choose CSS framework (Bootstrap 5)
2. Create responsive layouts
3. Update navigation
4. Responsive tables
5. Mobile-friendly forms
6. Test on multiple devices

📁 Files:
- `Take Time BangPhra/Styles/pms-responsive.css`
- `Take Time BangPhra/Styles/bootstrap-custom.css`
- Update all `.aspx` pages

---

## 📝 Migration Scripts Overview

### Migration 03: Add PMS Features
```sql
-- Guest Folio System
CREATE TABLE Guest_Folio (...)
CREATE TABLE Folio_Transaction (...)

-- Room Status
CREATE TABLE Room_Status (...)

-- Update Reservation
ALTER TABLE Reservation ADD ActualCheckInDate...

-- Stored Procedures
CREATE PROCEDURE sp_CreateGuestFolio
CREATE PROCEDURE sp_PostChargeToRoom
CREATE PROCEDURE sp_GetFolioBalance
CREATE PROCEDURE sp_CheckOutValidation
```

### Migration 04: Add Product Images
```sql
-- Product Images
CREATE TABLE Product_Images (...)

-- Update Product
ALTER TABLE Product ADD ShowInReservation...

-- Views
CREATE VIEW v_ProductsWithImages
```

### Migration 05: Add Payment Slips
```sql
-- Payment Slips
CREATE TABLE Payment_Slips (...)

-- File Management
CREATE PROCEDURE sp_SavePaymentSlip
CREATE PROCEDURE sp_GetPaymentSlips
```

---

## 🎨 UI/UX Mockups

### Reservation Page - Product Gallery

```
┌─────────────────────────────────────────────┐
│ จองห้องพัก                                  │
├─────────────────────────────────────────────┤
│                                             │
│ [ห้องพัก] [จำนวนคน] [วันที่]              │
│                                             │
├─────────────────────────────────────────────┤
│ สินค้าเพิ่มเติม                            │
│                                             │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│ │ [รูป]   │ │ [รูป]   │ │ [รูป]   │       │
│ │หมูกระทะ │ │ Set ไวน์│ │ BBQ Set │       │
│ │ 499 ฿   │ │ 1,200 ฿ │ │ 799 ฿   │       │
│ │ [+ เพิ่ม]│ │ [+ เพิ่ม]│ │ [+ เพิ่ม]│       │
│ └─────────┘ └─────────┘ └─────────┘       │
│                                             │
│ < Previous | Next >                        │
└─────────────────────────────────────────────┘
```

### Check-Out Page

```
┌─────────────────────────────────────────────┐
│ เช็คเอาท์ - ห้อง: บังกะโล 1                │
├─────────────────────────────────────────────┤
│ ชื่อผู้เข้าพัก: นาย ABC                    │
│ เช็คอิน: 01/11/2025                        │
│ เช็คเอาท์กำหนด: 03/11/2025                 │
├─────────────────────────────────────────────┤
│ สรุปค่าใช้จ่าย                             │
│                                             │
│ ค่าห้องพัก:              2,000 ฿          │
│ ค่าอาหาร/เครื่องดื่ม:      499 ฿          │
│ ค่าบริการอื่นๆ:            200 ฿          │
│ ─────────────────────────────────          │
│ รวม:                      2,699 ฿          │
│ ชำระแล้ว:                 1,000 ฿ (มัดจำ)  │
│ ─────────────────────────────────          │
│ คงค้าง:                   1,699 ฿          │
│                                             │
│ ⚠️ มียอดคงค้าง กรุณาชำระก่อนเช็คเอาท์      │
│                                             │
│ [ชำระเงิน] [ยกเลิก]                        │
└─────────────────────────────────────────────┘
```

---

## 🔧 Technical Stack

### Frontend:
- ASP.NET WebForms (existing)
- Bootstrap 5 (new)
- JavaScript/jQuery
- CSS Grid & Flexbox
- Font Awesome icons

### Backend:
- ASP.NET C#
- SQL Server 2014+
- LINQ to SQL / ADO.NET

### File Storage:
- Local file system
- Path: `/Uploads/PaymentSlips/`
- Path: `/Uploads/ProductImages/`

---

## ✅ Acceptance Criteria

### Product Gallery
- [ ] แสดงรูป product ได้
- [ ] เลื่อนดูรูปได้
- [ ] เลือกและเพิ่มจำนวนได้
- [ ] เพิ่มเข้า reservation ได้

### Guest Folio
- [ ] สร้าง folio อัตโนมัติเมื่อ check-in
- [ ] Post charges ลงบิลห้องได้
- [ ] แสดงยอดคงค้างได้
- [ ] Print folio ได้

### Check-in/Check-out
- [ ] เช็คอินได้
- [ ] ตรวจสอบยอดคงค้างก่อนเช็คเอาท์
- [ ] ถ้ามียอดค้าง block การเช็คเอาท์
- [ ] เช็คเอาท์ได้เมื่อไม่มียอดค้าง

### Payment Slips
- [ ] Upload slip ได้
- [ ] Preview slip ได้
- [ ] Required ในหน้าจองครั้งแรก
- [ ] Optional ในหน้าอื่น
- [ ] แยกแต่ละยอด

### Responsive Design
- [ ] ใช้งานได้บน Desktop
- [ ] ใช้งานได้บน Tablet
- [ ] ใช้งานได้บน Mobile
- [ ] Design เป็นทางการ สมส่วน

---

## 📅 Timeline Summary

| Phase | Duration | Priority | Status |
|-------|----------|----------|--------|
| Database & Backend | 1-2 weeks | HIGH | 🔵 Pending |
| Product Gallery | 1 week | HIGH | 🔵 Pending |
| Guest Folio | 1 week | HIGH | 🔵 Pending |
| Check-in/Check-out | 1-2 weeks | HIGH | 🔵 Pending |
| Payment Slips | 1 week | MEDIUM | 🔵 Pending |
| Responsive Design | 2 weeks | MEDIUM | 🔵 Pending |

**Total Estimated Time:** 6-8 weeks

---

## 🚀 Getting Started

### Step 1: Setup Database

```bash
# Apply migration system (if not done yet)
Database/Apply-Migrations.bat

# Will auto-apply all PMS migrations
```

### Step 2: Review Changes

```sql
-- Check new tables
SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%Folio%'
   OR TABLE_NAME LIKE '%Payment_Slip%'
   OR TABLE_NAME LIKE '%Product_Image%'
```

### Step 3: Start Development

Priority order:
1. Database migrations (this week)
2. Product gallery (next week)
3. Guest folio system
4. Check-in/check-out
5. Payment slips
6. Responsive design

---

## 📞 Notes & Considerations

### Security:
- [ ] Validate file uploads (size, type)
- [ ] Secure file storage
- [ ] Check user permissions
- [ ] SQL injection prevention
- [ ] XSS prevention

### Performance:
- [ ] Optimize image loading
- [ ] Cache product images
- [ ] Index new tables
- [ ] Optimize folio queries

### Backup:
- [ ] Backup before each migration
- [ ] Test on dev environment first
- [ ] Keep rollback scripts ready

---

**Created:** 2025-11-03
**Last Updated:** 2025-11-03
**Status:** 🔵 Planning Phase
