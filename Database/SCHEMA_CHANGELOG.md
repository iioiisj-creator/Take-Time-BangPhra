# Database Schema Changelog - PMS Upgrade

## Overview

This document tracks all database schema changes introduced by the PMS (Property Management System) upgrade migrations (03, 04, 05, 06).

**Important:** After applying all migrations, regenerate the main schema file using:
```sql
-- In SQL Server Management Studio:
-- Right-click on [Taketime] database
-- Tasks → Generate Scripts → Select all objects
-- Save as: Taketime_Database_Schema.sql
```

---

## Migration 03: Guest Folio System

### New Tables

#### 1. Guest_Folio
**Purpose:** Track guest billing accounts for room charges

```sql
CREATE TABLE [dbo].[Guest_Folio](
    [ID] [bigint] IDENTITY(1,1) PRIMARY KEY,
    [Reservation_ID] [bigint] NOT NULL,
    [FolioNumber] [nvarchar](20) NOT NULL UNIQUE,
    [Created_Date] [datetime] DEFAULT GETDATE(),
    [Closed_Date] [datetime] NULL,
    [Status] [nvarchar](20) DEFAULT 'OPEN', -- OPEN, CLOSED
    [TotalCharges] [decimal](18, 2) DEFAULT 0,
    [TotalPayments] [decimal](18, 2) DEFAULT 0,
    [Balance] AS ([TotalCharges] - [TotalPayments]) PERSISTED,
    [Notes] [nvarchar](1000) NULL
)
```

**Indexes:**
- `IX_Guest_Folio_ReservationID` on `Reservation_ID`
- `IX_Guest_Folio_Status` on `Status` WHERE `Status = 'OPEN'`
- `IX_Guest_Folio_FolioNumber` on `FolioNumber`

**Foreign Keys:**
- `FK_Guest_Folio_Reservation` → `Reservation(ID)` ON DELETE NO ACTION

#### 2. Folio_Transaction
**Purpose:** Track individual charges and payments on guest folios

```sql
CREATE TABLE [dbo].[Folio_Transaction](
    [ID] [bigint] IDENTITY(1,1) PRIMARY KEY,
    [Folio_ID] [bigint] NOT NULL,
    [TransactionDate] [datetime] DEFAULT GETDATE(),
    [TransactionType] [nvarchar](20) NOT NULL, -- CHARGE, PAYMENT, ADJUSTMENT
    [ProductType_ID] [tinyint] NULL,
    [Product_ID] [int] NULL,
    [Description] [nvarchar](500) NOT NULL,
    [Amount] [decimal](18, 2) NOT NULL,
    [Quantity] [decimal](10, 2) DEFAULT 1,
    [TotalAmount] AS ([Amount] * [Quantity]) PERSISTED,
    [PostedBy_ID] [smallint] NULL,
    [Reference] [nvarchar](100) NULL,
    [Notes] [nvarchar](500) NULL,
    [IsVoided] [bit] DEFAULT 0,
    [VoidedDate] [datetime] NULL,
    [VoidedBy_ID] [smallint] NULL,
    [Status] [tinyint] DEFAULT 1
)
```

**Indexes:**
- `IX_Folio_Transaction_FolioID` on `Folio_ID, TransactionDate DESC`
- `IX_Folio_Transaction_Type` on `TransactionType`
- `IX_Folio_Transaction_Product` on `Product_ID`

**Foreign Keys:**
- `FK_Folio_Transaction_Guest_Folio` → `Guest_Folio(ID)` ON DELETE CASCADE
- `FK_Folio_Transaction_ProductType` → `Account_ProductType(ID)` ON DELETE SET NULL
- `FK_Folio_Transaction_Product` → `Product(ID)` ON DELETE SET NULL
- `FK_Folio_Transaction_Employees_Posted` → `Employees(ID)` ON DELETE SET NULL
- `FK_Folio_Transaction_Employees_Voided` → `Employees(ID)` ON DELETE SET NULL

### Modified Tables

#### Reservation Table - New Columns:
```sql
ALTER TABLE [dbo].[Reservation] ADD
    [ActualCheckInDate] [datetime] NULL,
    [ActualCheckInBy_ID] [smallint] NULL,
    [ActualCheckOutDate] [datetime] NULL,
    [ActualCheckOutBy_ID] [smallint] NULL,
    [Folio_ID] [bigint] NULL,
    [HasOutstandingBalance] [bit] DEFAULT 0,
    [StatusReserve] [nvarchar](20) DEFAULT 'RESERVED'
```

**Foreign Keys:**
- `FK_Reservation_Employees_CheckIn` → `Employees(ID)` ON DELETE SET NULL
- `FK_Reservation_Employees_CheckOut` → `Employees(ID)` ON DELETE SET NULL
- `FK_Reservation_Guest_Folio` → `Guest_Folio(ID)` ON DELETE SET NULL

### New Stored Procedures

1. `sp_GenerateFolioNumber` - Generate unique folio numbers (F202511XXXX format)
2. `sp_CreateGuestFolio` - Create folio on check-in
3. `sp_PostChargeToRoom` - Post charges to guest folio
4. `sp_PostPayment` - Record payment on folio
5. `sp_VoidTransaction` - Void a folio transaction
6. `sp_CloseFolio` - Close folio on check-out
7. `sp_GetFolioSummary` - Get folio details with balance
8. `sp_GetFolioTransactions` - Get transaction history

### New Views

- `v_GuestFolioSummary` - Guest folio overview with customer and reservation details

---

## Migration 04: Product Images System

### New Tables

#### 1. Product_Images
**Purpose:** Store product photos for gallery display

```sql
CREATE TABLE [dbo].[Product_Images](
    [ID] [bigint] IDENTITY(1,1) PRIMARY KEY,
    [Product_ID] [int] NOT NULL,
    [ImageURL] [nvarchar](500) NOT NULL,
    [ImageTitle] [nvarchar](200) NULL,
    [ImageDescription] [nvarchar](500) NULL,
    [DisplayOrder] [int] DEFAULT 0,
    [IsActive] [bit] DEFAULT 1,
    [IsPrimary] [bit] DEFAULT 0,
    [UploadedDate] [datetime] DEFAULT GETDATE(),
    [UploadedBy_ID] [smallint] NULL,
    [FileSize] [int] NULL,
    [ImageWidth] [smallint] NULL,
    [ImageHeight] [smallint] NULL,
    [AltText] [nvarchar](200) NULL,
    [Status] [tinyint] DEFAULT 1
)
```

**Indexes:**
- `IX_Product_Images_ProductID` on `Product_ID, DisplayOrder` INCLUDE `ImageURL, IsPrimary, IsActive`
- `IX_Product_Images_Active` on `Product_ID, IsActive, DisplayOrder` WHERE `IsActive = 1 AND Status = 1`
- `IX_Product_Images_Primary` on `Product_ID, IsPrimary` WHERE `IsPrimary = 1 AND IsActive = 1`

**Foreign Keys:**
- `FK_Product_Images_Product` → `Product(ID)` ON DELETE CASCADE
- `FK_Product_Images_Employees` → `Employees(ID)` ON DELETE SET NULL

**Check Constraints:**
- `CK_Product_Images_DisplayOrder` CHECK `DisplayOrder >= 0`
- `CK_Product_Images_Status` CHECK `Status IN (0, 1)`
- `CK_Product_Images_FileSize` CHECK `FileSize IS NULL OR FileSize > 0`
- `CK_Product_Images_ImageWidth` CHECK `ImageWidth IS NULL OR ImageWidth > 0`
- `CK_Product_Images_ImageHeight` CHECK `ImageHeight IS NULL OR ImageHeight > 0`

### Modified Tables

#### Product Table - New Columns:
```sql
ALTER TABLE [dbo].[Product] ADD
    [ShowInReservation] [bit] DEFAULT 0,
    [HasImages] [bit] DEFAULT 0,
    [ReservationDisplayOrder] [int] DEFAULT 999
```

### New Stored Procedures

1. `sp_GetProductImages` - Get all images for a product
2. `sp_GetProductsForReservation` - Get products to show in reservation gallery
3. `sp_AddProductImage` - Add new product image
4. `sp_SetPrimaryProductImage` - Set primary image for product

### New Views

- `v_ProductGallery` - Product gallery with images and metadata

---

## Migration 05: Payment Slips System

### New Tables

#### 1. Payment_Slips
**Purpose:** Store uploaded payment slip/receipt images

```sql
CREATE TABLE [dbo].[Payment_Slips](
    [ID] [bigint] IDENTITY(1,1) PRIMARY KEY,
    [Account_Receipt_ID] [bigint] NOT NULL,
    [Reservation_ID] [bigint] NOT NULL,
    [SlipFileURL] [nvarchar](500) NOT NULL,
    [FileName] [nvarchar](255) NOT NULL,
    [FileType] [nvarchar](50) NULL,
    [FileSize] [int] NULL,
    [UploadedDate] [datetime] DEFAULT GETDATE(),
    [UploadedBy_ID] [smallint] NULL,
    [UploadedBy_CustomerPhone] [nvarchar](20) NULL,
    [IsVerified] [bit] DEFAULT 0,
    [VerifiedBy_ID] [smallint] NULL,
    [VerifiedDate] [datetime] NULL,
    [VerificationStatus] [nvarchar](20) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    [RejectionReason] [nvarchar](500) NULL,
    [Notes] [nvarchar](1000) NULL,
    [IsActive] [bit] DEFAULT 1,
    [Status] [tinyint] DEFAULT 1
)
```

**Indexes:**
- `IX_Payment_Slips_ReceiptID` on `Account_Receipt_ID` INCLUDE `VerificationStatus, IsActive`
- `IX_Payment_Slips_ReservationID` on `Reservation_ID, UploadedDate DESC`
- `IX_Payment_Slips_PendingVerification` on `VerificationStatus, UploadedDate DESC` WHERE `IsActive = 1 AND Status = 1 AND VerificationStatus = 'PENDING'`

**Foreign Keys:**
- `FK_Payment_Slips_Account_Receipt` → `Account_Receipt(ID)` ON DELETE CASCADE
- `FK_Payment_Slips_Reservation` → `Reservation(ID)` ON DELETE NO ACTION
- `FK_Payment_Slips_Employees_Upload` → `Employees(ID)` ON DELETE SET NULL
- `FK_Payment_Slips_Employees_Verify` → `Employees(ID)` ON DELETE SET NULL
- `FK_Payment_Slips_Customer` → `Customer(MobilePhone)` ON DELETE SET NULL

**Check Constraints:**
- `CK_Payment_Slips_VerificationStatus` CHECK `VerificationStatus IN ('PENDING', 'APPROVED', 'REJECTED')`
- `CK_Payment_Slips_FileSize` CHECK `FileSize IS NULL OR FileSize > 0`
- `CK_Payment_Slips_Status` CHECK `Status IN (0, 1)`
- `CK_Payment_Slips_Verification` CHECK `IsVerified = 0 OR (IsVerified = 1 AND VerifiedBy_ID IS NOT NULL AND VerifiedDate IS NOT NULL)`

### Modified Tables

#### Account_Receipt Table - New Columns:
```sql
ALTER TABLE [dbo].[Account_Receipt] ADD
    [HasPaymentSlip] [bit] DEFAULT 0,
    [PaymentSlipRequired] [bit] DEFAULT 0
```

### New Stored Procedures

1. `sp_UploadPaymentSlip` - Upload payment slip file
2. `sp_VerifyPaymentSlip` - Verify/approve/reject slip
3. `sp_GetPaymentSlips` - Get slips for reservation or receipt
4. `sp_IsPaymentSlipRequired` - Check if slip is required for this payment

### New Views

- `v_PaymentSlipsSummary` - Payment slips with reservation and customer details

---

## Migration 06: Room Status System

### New Tables

#### 1. Room_Status
**Purpose:** Track real-time room status and housekeeping

```sql
CREATE TABLE [dbo].[Room_Status](
    [ID] [bigint] IDENTITY(1,1) PRIMARY KEY,
    [Accommodation_ID] [int] NOT NULL UNIQUE,
    [CurrentStatus] [nvarchar](30) DEFAULT 'VACANT_CLEAN',
    [HousekeepingStatus] [nvarchar](30) DEFAULT 'CLEAN',
    [OccupancyStatus] [nvarchar](30) DEFAULT 'VACANT',
    [IsOccupied] [bit] DEFAULT 0,
    [CurrentReservation_ID] [bigint] NULL,
    [CurrentGuest_Name] [nvarchar](200) NULL,
    [CheckedInDate] [datetime] NULL,
    [ExpectedCheckOutDate] [datetime] NULL,
    [LastCleanedDate] [datetime] NULL,
    [LastCleanedBy_ID] [smallint] NULL,
    [MaintenanceRequired] [bit] DEFAULT 0,
    [MaintenanceNotes] [nvarchar](1000) NULL,
    [MaintenanceStartDate] [datetime] NULL,
    [MaintenanceEndDate] [datetime] NULL,
    [LastStatusChange] [datetime] DEFAULT GETDATE(),
    [LastStatusChangedBy_ID] [smallint] NULL,
    [Notes] [nvarchar](1000) NULL,
    [IsActive] [bit] DEFAULT 1,
    [Status] [tinyint] DEFAULT 1
)
```

**Indexes:**
- `IX_Room_Status_CurrentStatus` on `CurrentStatus, IsActive` INCLUDE `Accommodation_ID, IsOccupied`
- `IX_Room_Status_OccupancyStatus` on `OccupancyStatus, IsActive`
- `IX_Room_Status_HousekeepingStatus` on `HousekeepingStatus, IsActive`
- `IX_Room_Status_CurrentReservation` on `CurrentReservation_ID` WHERE `CurrentReservation_ID IS NOT NULL`

**Foreign Keys:**
- `FK_Room_Status_Accommodation` → `Accommodation(ID)` ON DELETE CASCADE
- `FK_Room_Status_Reservation` → `Reservation(ID)` ON DELETE SET NULL
- `FK_Room_Status_Employees_Cleaned` → `Employees(ID)` ON DELETE SET NULL
- `FK_Room_Status_Employees_StatusChange` → `Employees(ID)` ON DELETE SET NULL

**Check Constraints:**
- `CK_Room_Status_CurrentStatus` CHECK `CurrentStatus IN ('VACANT_CLEAN', 'VACANT_DIRTY', 'OCCUPIED_CLEAN', 'OCCUPIED_DIRTY', 'OUT_OF_ORDER', 'RESERVED')`
- `CK_Room_Status_HousekeepingStatus` CHECK `HousekeepingStatus IN ('CLEAN', 'DIRTY', 'IN_PROGRESS', 'INSPECTED')`
- `CK_Room_Status_OccupancyStatus` CHECK `OccupancyStatus IN ('VACANT', 'OCCUPIED', 'RESERVED', 'OUT_OF_ORDER')`
- `CK_Room_Status_Status` CHECK `Status IN (0, 1)`

#### 2. Room_Status_History
**Purpose:** Track room status changes over time

```sql
CREATE TABLE [dbo].[Room_Status_History](
    [ID] [bigint] IDENTITY(1,1) PRIMARY KEY,
    [Room_Status_ID] [bigint] NOT NULL,
    [Accommodation_ID] [int] NOT NULL,
    [PreviousStatus] [nvarchar](30) NULL,
    [NewStatus] [nvarchar](30) NOT NULL,
    [ChangeDate] [datetime] DEFAULT GETDATE(),
    [ChangedBy_ID] [smallint] NULL,
    [ChangeReason] [nvarchar](500) NULL,
    [Reservation_ID] [bigint] NULL,
    [Notes] [nvarchar](1000) NULL
)
```

**Indexes:**
- `IX_Room_Status_History_Accommodation` on `Accommodation_ID, ChangeDate DESC`

**Foreign Keys:**
- `FK_Room_Status_History_Room_Status` → `Room_Status(ID)` ON DELETE CASCADE
- `FK_Room_Status_History_Accommodation` → `Accommodation(ID)` ON DELETE NO ACTION
- `FK_Room_Status_History_Employees` → `Employees(ID)` ON DELETE SET NULL

### New Stored Procedures

1. `sp_UpdateRoomStatus` - Update room status with history tracking
2. `sp_MarkRoomCleaned` - Mark room as cleaned
3. `sp_CheckInUpdateRoomStatus` - Update room status on check-in
4. `sp_CheckOutUpdateRoomStatus` - Update room status on check-out

### New Views

- `v_RoomStatusDashboard` - Real-time room status overview

---

## Migration 00: Database Migration System

### New Tables

#### Database_Migrations
**Purpose:** Track which migrations have been applied

```sql
CREATE TABLE [dbo].[Database_Migrations](
    [ID] [int] IDENTITY(1,1) PRIMARY KEY,
    [MigrationName] [nvarchar](255) NOT NULL,
    [AppliedDate] [datetime] DEFAULT GETDATE(),
    [AppliedBy] [nvarchar](100) NULL,
    [ScriptContent] [ntext] NULL,
    [Success] [bit] DEFAULT 1,
    [ErrorMessage] [ntext] NULL,
    [ExecutionTimeMs] [int] NULL
)
```

### New Stored Procedures

1. `sp_IsMigrationApplied` - Check if migration was applied
2. `sp_RecordMigration` - Record migration execution

### New Views

- `v_MigrationHistory` - Migration history with status

---

## Summary of Changes

### New Tables (9)
1. `Database_Migrations`
2. `Guest_Folio`
3. `Folio_Transaction`
4. `Product_Images`
5. `Payment_Slips`
6. `Room_Status`
7. `Room_Status_History`

### Modified Tables (3)
1. `Reservation` - Added 7 columns for check-in/check-out tracking
2. `Product` - Added 3 columns for gallery display
3. `Account_Receipt` - Added 2 columns for payment slip tracking

### New Stored Procedures (20+)
- Guest Folio Management (8 procedures)
- Product Images Management (4 procedures)
- Payment Slips Management (4 procedures)
- Room Status Management (4 procedures)
- Migration System (2 procedures)

### New Views (5)
- `v_MigrationHistory`
- `v_GuestFolioSummary`
- `v_ProductGallery`
- `v_PaymentSlipsSummary`
- `v_RoomStatusDashboard`

---

## Testing Checklist

After applying all migrations:

- [ ] Verify all tables exist
- [ ] Verify all foreign keys are in place
- [ ] Verify all check constraints work
- [ ] Verify all indexes are created
- [ ] Test all stored procedures
- [ ] Verify views return data correctly
- [ ] Test check-in/check-out flow
- [ ] Test product gallery display
- [ ] Test payment slip upload
- [ ] Test room status updates
- [ ] Verify migration system tracking
- [ ] Regenerate full schema file from database

---

## Regenerating Schema File

To regenerate the complete schema file after all migrations:

1. Open SQL Server Management Studio
2. Connect to server
3. Right-click on `[Taketime]` database
4. Select: **Tasks** → **Generate Scripts**
5. Click **Next** on welcome screen
6. Select: **Select specific database objects**
7. Check: **Tables**, **Views**, **Stored Procedures**, **Functions**
8. Click **Next**
9. Click **Advanced** button
10. Set these options:
    - Script Indexes: **True**
    - Script Foreign Keys: **True**
    - Script Primary Keys: **True**
    - Script Unique Keys: **True**
    - Script Check Constraints: **True**
    - Script Default Constraints: **True**
    - Type of data to script: **Schema only**
11. Click **OK**, then **Next**
12. Choose: **Save to file**
13. Save as: `Database/Taketime_Database_Schema.sql`
14. Click **Next**, then **Finish**

---

## Version History

| Version | Date | Migration | Description |
|---------|------|-----------|-------------|
| 1.0 | 2025-11-03 | 00 | Database migration system |
| 2.0 | 2025-11-03 | 03 | Guest folio system for PMS |
| 2.1 | 2025-11-03 | 04 | Product images for gallery |
| 2.2 | 2025-11-03 | 05 | Payment slip uploads |
| 2.3 | 2025-11-03 | 06 | Room status management |

---

**Last Updated:** 2025-11-03
**Maintained By:** Development Team
**Schema Version:** 2.3
