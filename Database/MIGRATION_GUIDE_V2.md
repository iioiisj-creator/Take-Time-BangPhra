# Migration Guide V2 - Based on Current Database Schema

## Overview

This guide provides step-by-step instructions for running database migrations 07 and 08 on the current Taketime database.

**Key improvements in V2:**
- ✅ Works with your current database structure
- ✅ Checks if columns already exist before adding them
- ✅ No need to clean duplicate data (uses ID as primary key)
- ✅ Safe to run multiple times (idempotent)

---

## Pre-requisites

✅ **Database:** Taketime database exists
✅ **Tables:** Customer, Admin, Account_Receipt tables exist
✅ **Migration System:** Database_Migrations table and stored procedures exist
✅ **SQL Server:** Version 2016 or later

---

## Migration Files

### Migration 07: Customer Management Enhancement V2
**File:** `07_Add_Customer_Management_Enhancement_v2.sql`

**What it does:**
- Adds Primary Key to Admin.ID (if missing)
- Creates Customer_Audit_Log table for tracking changes
- Ensures Customer table has audit columns (LastUpdated, CreatedDate, etc.)
- Creates Foreign Keys to Admin table
- Adds performance indexes
- Creates sp_UpsertCustomer stored procedure

**Safe to run:** YES - checks if each item exists before creating

---

### Migration 08: Accounting System V2
**File:** `08_Add_Standard_Accounting_System_v2.sql`

**What it does:**
- Adds revenue tracking columns to Account_Receipt
- Adds PaymentChannel, RevenueCategory, TransactionDate columns
- Creates indexes for performance
- Creates revenue summary views
- Creates reporting stored procedures
- Updates existing data with default values

**Safe to run:** YES - checks if each column exists before adding

---

## Step-by-Step Instructions

### Step 1: Backup Database

```sql
-- In SQL Server Management Studio (SSMS)
-- Right-click Taketime database
-- Tasks → Back Up...
-- Click OK
```

Or via SQL:
```sql
BACKUP DATABASE [Taketime]
TO DISK = 'C:\Backup\Taketime_Backup_Before_Migration.bak'
WITH FORMAT, NAME = 'Full Backup Before Migration';
```

---

### Step 2: Run Migration 07

1. **Open SQL Server Management Studio (SSMS)**

2. **Connect to your server**

3. **Open file:**
   ```
   Database/07_Add_Customer_Management_Enhancement_v2.sql
   ```

4. **Press F5 or click Execute**

5. **Expected output:**
   ```
   =============================================================
   Migration: 07_Add_Customer_Management_Enhancement_v2
   Started: 2025-11-04 ...
   =============================================================

   Running pre-flight checks...
   Customer table exists
   Admin table exists

   Starting database modifications...

   Step 1: Ensuring Admin table has Primary Key...
     Added Primary Key to Admin.ID
     (or: Admin.ID already has a Primary Key)

   Step 2: Creating Customer_Audit_Log table...
     Created Customer_Audit_Log table
     (or: Customer_Audit_Log table already exists)

   Step 3: Checking Customer table columns...
     LastUpdated column already exists
     LastUpdatedBy_ID column already exists
     CreatedDate column already exists
     CreatedBy_ID column already exists
     IsActive column already exists
     Other columns (TaxID, District, ...) already exist

   Step 4: Adding foreign key constraints...
     Added FK_Customer_Audit_Log_Customer
     Added FK_Customer_Audit_Log_Admin
     Added FK_Customer_Admin_LastUpdated
     Added FK_Customer_Admin_Created

   Step 5: Creating performance indexes...
     Created IX_Customer_Audit_Log_Customer
     Created IX_Customer_MobilePhone
     Created IX_Customer_Email
     Created IX_Customer_TaxID
     Created IX_Customer_IsActive

   Step 6: Creating stored procedures...
     Created sp_UpsertCustomer

   Step 7: Updating existing customer records...
     Updated existing customer records

   =============================================================
   Migration completed successfully!
   Execution time: XXXX ms
   =============================================================
   ```

6. **If you see errors:** Take a screenshot and check the troubleshooting section below

---

### Step 3: Verify Migration 07

Run this query to verify:

```sql
-- Check migration was recorded
SELECT *
FROM Database_Migrations
WHERE MigrationName = '07_Add_Customer_Management_Enhancement_v2'

-- Should show:
-- Success = 1
-- ErrorMessage = NULL
```

Expected result:
```
ID  MigrationName                                    Success  AppliedDate
1   07_Add_Customer_Management_Enhancement_v2        1        2025-11-04 ...
```

---

### Step 4: Run Migration 08

1. **Open file:**
   ```
   Database/08_Add_Standard_Accounting_System_v2.sql
   ```

2. **Press F5 or click Execute**

3. **Expected output:**
   ```
   =============================================================
   Migration: 08_Add_Standard_Accounting_System_v2
   Started: 2025-11-04 ...
   =============================================================

   Running pre-flight checks...
   Account_Receipt table exists

   Starting database modifications...

   Step 1: Adding columns to Account_Receipt...
     Added RevenueCategory column
     Added PaymentChannel column
     Added TransactionDate column
     Added ProductType_ID column
     Added IsFrontTransaction column

   Step 2: Creating indexes...
     Created IX_Account_Receipt_RevenueCategory
     Created IX_Account_Receipt_PaymentChannel
     Created IX_Account_Receipt_TransactionDate

   Step 3: Creating views...
     Created v_RevenueSummary

   Step 4: Creating stored procedures...
     Created sp_GetRevenueSummaryByCategory
     Created sp_GetRevenueSummaryByPaymentChannel
     Created sp_GetDailyRevenueSummary

   Step 5: Updating existing data...
     Updated TransactionDate for XXXX records
     Updated PaymentChannel from Paid_Type
     Updated RevenueCategory
     Updated IsFrontTransaction

   =============================================================
   Migration completed successfully!
   Execution time: XXXX ms
   =============================================================
   ```

---

### Step 5: Verify Migration 08

```sql
-- Check migration was recorded
SELECT *
FROM Database_Migrations
WHERE MigrationName = '08_Add_Standard_Accounting_System_v2'
ORDER BY AppliedDate DESC

-- Check new columns exist
SELECT TOP 5
    ID,
    Created_Date,
    TransactionDate,
    RevenueCategory,
    PaymentChannel,
    Total_Amount
FROM Account_Receipt
ORDER BY Created_Date DESC
```

---

## Testing New Features

### Test 1: Customer Audit Trail

```sql
-- Use the new stored procedure
DECLARE @CustomerID BIGINT

EXEC sp_UpsertCustomer
    @ID = @CustomerID OUTPUT,
    @MobilePhone = '0812345678',
    @Name = 'ทดสอบ ระบบ',
    @Email = 'test@example.com',
    @ChangedBy_ID = 1,
    @ChangedBy_Source = 'Manual Test',
    @IPAddress = '127.0.0.1'

-- Check audit log
SELECT *
FROM Customer_Audit_Log
WHERE Customer_ID = @CustomerID
```

### Test 2: Revenue Reports

```sql
-- Get revenue by category
EXEC sp_GetRevenueSummaryByCategory
    @StartDate = '2025-01-01',
    @EndDate = '2025-12-31'

-- Get revenue by payment channel
EXEC sp_GetRevenueSummaryByPaymentChannel
    @StartDate = '2025-01-01',
    @EndDate = '2025-12-31'

-- Get daily revenue summary
EXEC sp_GetDailyRevenueSummary
    @StartDate = '2025-11-01',
    @EndDate = '2025-11-30'
```

### Test 3: Revenue Summary View

```sql
SELECT TOP 20
    TransactionDate,
    CustomerName,
    Total_Amount,
    RevenueCategory,
    PaymentChannel,
    TransactionType
FROM v_RevenueSummary
ORDER BY TransactionDate DESC
```

---

## Troubleshooting

### Error: "Migration already applied"

**Cause:** Migration was already run successfully

**Solution:** This is safe! The migration is skipped. No action needed.

---

### Error: "Admin table does not exist"

**Cause:** Database is missing required tables

**Solution:** Check database name and connection. You may be connected to the wrong database.

---

### Error: "Could not create constraint or index"

**Cause:** Data integrity issue (rare with V2)

**Solution:**
1. Check error details
2. Contact support with full error message

---

### Error: "There is already an object named 'PK_Admin' in the database"

**Cause:** Primary Key already exists

**Solution:** This is safe! The script will detect this and skip. If you see this error, the migration may need adjustment.

---

## Rollback Instructions

If you need to rollback (undo) the migrations:

### Rollback Migration 08

```sql
-- Remove columns
ALTER TABLE Account_Receipt DROP COLUMN IF EXISTS RevenueCategory
ALTER TABLE Account_Receipt DROP COLUMN IF EXISTS PaymentChannel
ALTER TABLE Account_Receipt DROP COLUMN IF EXISTS TransactionDate
ALTER TABLE Account_Receipt DROP COLUMN IF EXISTS ProductType_ID
ALTER TABLE Account_Receipt DROP COLUMN IF EXISTS IsFrontTransaction

-- Drop views
DROP VIEW IF EXISTS v_RevenueSummary

-- Drop procedures
DROP PROCEDURE IF EXISTS sp_GetRevenueSummaryByCategory
DROP PROCEDURE IF EXISTS sp_GetRevenueSummaryByPaymentChannel
DROP PROCEDURE IF EXISTS sp_GetDailyRevenueSummary

-- Remove migration record
DELETE FROM Database_Migrations
WHERE MigrationName = '08_Add_Standard_Accounting_System_v2'
```

### Rollback Migration 07

```sql
-- Remove Foreign Keys
ALTER TABLE Customer DROP CONSTRAINT IF EXISTS FK_Customer_Admin_Created
ALTER TABLE Customer DROP CONSTRAINT IF EXISTS FK_Customer_Admin_LastUpdated
ALTER TABLE Customer_Audit_Log DROP CONSTRAINT IF EXISTS FK_Customer_Audit_Log_Admin
ALTER TABLE Customer_Audit_Log DROP CONSTRAINT IF EXISTS FK_Customer_Audit_Log_Customer

-- Drop table
DROP TABLE IF EXISTS Customer_Audit_Log

-- Drop procedure
DROP PROCEDURE IF EXISTS sp_UpsertCustomer

-- Remove migration record
DELETE FROM Database_Migrations
WHERE MigrationName = '07_Add_Customer_Management_Enhancement_v2'
```

**Note:** Rollback does NOT remove Admin.ID Primary Key (it's needed for database integrity)

---

## Summary

✅ **Migration 07:** Customer management with audit trail
✅ **Migration 08:** Accounting system with revenue tracking

**Total time:** Usually 1-5 seconds per migration

**Safe to re-run:** Yes, both migrations check for existing objects

**Production ready:** Yes, includes full transaction support and error handling

---

## Next Steps

After successful migration:

1. ✅ Test the new stored procedures
2. ✅ Update your application code to use `sp_UpsertCustomer`
3. ✅ Build reports using the new revenue views
4. ✅ Train users on the new features

---

## Support

If you encounter any issues:

1. Take a screenshot of the error
2. Note the exact error message
3. Check which step failed
4. Check Database_Migrations table for error details:
   ```sql
   SELECT * FROM Database_Migrations
   WHERE Success = 0
   ORDER BY AppliedDate DESC
   ```

---

**Document Version:** 2.0
**Last Updated:** 2025-11-04
**Author:** Claude
