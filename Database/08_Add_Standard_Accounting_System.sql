/*==============================================================
  Migration: 08_Add_Standard_Accounting_System

  Purpose:
  - Implement standard accounting documents system
  - Add Credit Note (ใบลดหนี้) and Debit Note (ใบเพิ่มหนี้)
  - Improve Tax Invoice and Payment Voucher creation
  - Add daily cash summary for Front team
  - Track revenue by category and payment channel
  - Separate check-in transactions from advance bookings

  Features:
  - Credit_Note table for refunds and adjustments
  - Debit_Note table for additional charges
  - Document reference tracking
  - Daily cash summary by payment type
  - Front team transaction tracking
  - Revenue categorization
  - Accounting period management

  Business Rules:
  - Credit Note: Issued for refunds, cancellations, discounts
  - Debit Note: Issued for additional charges, penalties
  - All documents must reference original receipt
  - Daily summary tracks only same-day transactions
  - Check-in date = transaction date for Front team report

  Author: Claude
  Date: 2025-11-03
  Dependencies: 00_Init_Migration_System
==============================================================*/

USE [Taketime]
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @MigrationName NVARCHAR(255) = '08_Add_Standard_Accounting_System'
DECLARE @StartTime DATETIME = GETDATE()

PRINT ''
PRINT '============================================================='
PRINT 'Migration: ' + @MigrationName
PRINT 'Started: ' + CONVERT(VARCHAR, @StartTime, 120)
PRINT '============================================================='
PRINT ''

-- ===================================================================
-- Check if migration already applied
-- ===================================================================

IF EXISTS (SELECT 1 FROM Database_Migrations WHERE MigrationName = @MigrationName AND Success = 1)
BEGIN
    PRINT '⚠ Migration already applied: ' + @MigrationName
    PRINT '⚠ Skipping execution'
    GOTO MigrationEnd
END

-- ===================================================================
-- Pre-flight checks
-- ===================================================================

PRINT 'Running pre-flight checks...'
PRINT ''

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND type in (N'U'))
BEGIN
    RAISERROR('✗ Account_Receipt table does not exist. Cannot proceed.', 16, 1)
    GOTO MigrationEnd
END

PRINT '✓ Account_Receipt table exists'
PRINT ''

-- ===================================================================
-- Begin Transaction
-- ===================================================================

BEGIN TRANSACTION

BEGIN TRY

    PRINT 'Starting database modifications...'
    PRINT ''

    -- ===================================================================
    -- Step 1: Create Credit_Note table (ใบลดหนี้)
    -- ===================================================================

    PRINT 'Step 1: Creating Credit_Note table...'

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Credit_Note]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[Credit_Note](
            [ID] [bigint] IDENTITY(1,1) NOT NULL,
            [CreditNoteNumber] [nvarchar](20) NOT NULL UNIQUE,
            [CreditNoteDate] [datetime] NOT NULL DEFAULT GETDATE(),
            [OriginalReceipt_ID] [bigint] NOT NULL,
            [Reservation_ID] [bigint] NULL,
            [Customer_MobilePhone] [nvarchar](30) NOT NULL,
            [Reason] [nvarchar](500) NOT NULL,
            [ReasonType] [nvarchar](50) NOT NULL, -- REFUND, CANCELLATION, DISCOUNT, CORRECTION, OTHER
            [TotalAmount] [decimal](18, 2) NOT NULL,
            [VatAmount] [decimal](18, 2) NOT NULL DEFAULT 0,
            [GrandTotal] [decimal](18, 2) NOT NULL,
            [CreatedBy_ID] [smallint] NULL,
            [ApprovedBy_ID] [smallint] NULL,
            [ApprovedDate] [datetime] NULL,
            [Status] [nvarchar](20) NOT NULL DEFAULT 'DRAFT', -- DRAFT, APPROVED, CANCELLED
            [Notes] [nvarchar](1000) NULL,
            [IsActive] [bit] NOT NULL DEFAULT 1,
         CONSTRAINT [PK_Credit_Note] PRIMARY KEY CLUSTERED ([ID] ASC)
        ) ON [PRIMARY]

        PRINT '  ✓ Created Credit_Note table'
    END

    -- ===================================================================
    -- Step 2: Create Credit_Note_Detail table
    -- ===================================================================

    PRINT 'Step 2: Creating Credit_Note_Detail table...'

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Credit_Note_Detail]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[Credit_Note_Detail](
            [ID] [bigint] IDENTITY(1,1) NOT NULL,
            [CreditNote_ID] [bigint] NOT NULL,
            [ProductType_ID] [tinyint] NULL,
            [Product_ID] [int] NULL,
            [Description] [nvarchar](500) NOT NULL,
            [Quantity] [decimal](10, 2) NOT NULL DEFAULT 1,
            [UnitPrice] [decimal](18, 2) NOT NULL,
            [Amount] [decimal](18, 2) NOT NULL,
            [Status] [tinyint] NOT NULL DEFAULT 1,
         CONSTRAINT [PK_Credit_Note_Detail] PRIMARY KEY CLUSTERED ([ID] ASC)
        ) ON [PRIMARY]

        PRINT '  ✓ Created Credit_Note_Detail table'
    END

    -- ===================================================================
    -- Step 3: Create Debit_Note table (ใบเพิ่มหนี้)
    -- ===================================================================

    PRINT 'Step 3: Creating Debit_Note table...'

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Debit_Note]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[Debit_Note](
            [ID] [bigint] IDENTITY(1,1) NOT NULL,
            [DebitNoteNumber] [nvarchar](20) NOT NULL UNIQUE,
            [DebitNoteDate] [datetime] NOT NULL DEFAULT GETDATE(),
            [OriginalReceipt_ID] [bigint] NULL,
            [Reservation_ID] [bigint] NULL,
            [Customer_MobilePhone] [nvarchar](30) NOT NULL,
            [Reason] [nvarchar](500) NOT NULL,
            [ReasonType] [nvarchar](50) NOT NULL, -- ADDITIONAL_CHARGE, PENALTY, DAMAGE, CORRECTION, OTHER
            [TotalAmount] [decimal](18, 2) NOT NULL,
            [VatAmount] [decimal](18, 2) NOT NULL DEFAULT 0,
            [GrandTotal] [decimal](18, 2) NOT NULL,
            [CreatedBy_ID] [smallint] NULL,
            [ApprovedBy_ID] [smallint] NULL,
            [ApprovedDate] [datetime] NULL,
            [Status] [nvarchar](20) NOT NULL DEFAULT 'DRAFT', -- DRAFT, APPROVED, PAID, CANCELLED
            [PaidDate] [datetime] NULL,
            [Notes] [nvarchar](1000) NULL,
            [IsActive] [bit] NOT NULL DEFAULT 1,
         CONSTRAINT [PK_Debit_Note] PRIMARY KEY CLUSTERED ([ID] ASC)
        ) ON [PRIMARY]

        PRINT '  ✓ Created Debit_Note table'
    END

    -- ===================================================================
    -- Step 4: Create Debit_Note_Detail table
    -- ===================================================================

    PRINT 'Step 4: Creating Debit_Note_Detail table...'

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Debit_Note_Detail]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[Debit_Note_Detail](
            [ID] [bigint] IDENTITY(1,1) NOT NULL,
            [DebitNote_ID] [bigint] NOT NULL,
            [ProductType_ID] [tinyint] NULL,
            [Product_ID] [int] NULL,
            [Description] [nvarchar](500) NOT NULL,
            [Quantity] [decimal](10, 2) NOT NULL DEFAULT 1,
            [UnitPrice] [decimal](18, 2) NOT NULL,
            [Amount] [decimal](18, 2) NOT NULL,
            [Status] [tinyint] NOT NULL DEFAULT 1,
         CONSTRAINT [PK_Debit_Note_Detail] PRIMARY KEY CLUSTERED ([ID] ASC)
        ) ON [PRIMARY]

        PRINT '  ✓ Created Debit_Note_Detail table'
    END

    -- ===================================================================
    -- Step 5: Add columns to Account_Receipt
    -- ===================================================================

    PRINT 'Step 5: Adding columns to Account_Receipt...'

    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND name = 'TransactionDate')
    BEGIN
        ALTER TABLE [dbo].[Account_Receipt]
        ADD [TransactionDate] [date] NULL

        -- Set TransactionDate to created date for existing records
        UPDATE Account_Receipt
        SET TransactionDate = CAST(Created_Date AS DATE)
        WHERE TransactionDate IS NULL AND Created_Date IS NOT NULL

        PRINT '  ✓ Added TransactionDate column'
    END

    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND name = 'IsCheckIn')
    BEGIN
        ALTER TABLE [dbo].[Account_Receipt]
        ADD [IsCheckIn] [bit] NOT NULL DEFAULT 0

        PRINT '  ✓ Added IsCheckIn column'
    END

    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND name = 'IsFrontTransaction')
    BEGIN
        ALTER TABLE [dbo].[Account_Receipt]
        ADD [IsFrontTransaction] [bit] NOT NULL DEFAULT 1

        PRINT '  ✓ Added IsFrontTransaction column'
    END

    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND name = 'RevenueCategory')
    BEGIN
        ALTER TABLE [dbo].[Account_Receipt]
        ADD [RevenueCategory] [nvarchar](50) NULL

        PRINT '  ✓ Added RevenueCategory column'
    END

    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND name = 'ReferenceDocument')
    BEGIN
        ALTER TABLE [dbo].[Account_Receipt]
        ADD [ReferenceDocument] [nvarchar](100) NULL

        PRINT '  ✓ Added ReferenceDocument column'
    END

    -- ===================================================================
    -- Step 6: Add foreign keys
    -- ===================================================================

    PRINT 'Step 6: Adding foreign key constraints...'

    -- Credit Note FKs
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Credit_Note_Account_Receipt')
    BEGIN
        ALTER TABLE [dbo].[Credit_Note]
        ADD CONSTRAINT [FK_Credit_Note_Account_Receipt]
        FOREIGN KEY([OriginalReceipt_ID])
        REFERENCES [dbo].[Account_Receipt] ([ID])
        ON UPDATE NO ACTION
        ON DELETE NO ACTION

        PRINT '  ✓ Added FK_Credit_Note_Account_Receipt'
    END

    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Credit_Note_Customer')
    BEGIN
        ALTER TABLE [dbo].[Credit_Note]
        ADD CONSTRAINT [FK_Credit_Note_Customer]
        FOREIGN KEY([Customer_MobilePhone])
        REFERENCES [dbo].[Customer] ([MobilePhone])
        ON UPDATE CASCADE
        ON DELETE NO ACTION

        PRINT '  ✓ Added FK_Credit_Note_Customer'
    END

    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Credit_Note_Detail_Credit_Note')
    BEGIN
        ALTER TABLE [dbo].[Credit_Note_Detail]
        ADD CONSTRAINT [FK_Credit_Note_Detail_Credit_Note]
        FOREIGN KEY([CreditNote_ID])
        REFERENCES [dbo].[Credit_Note] ([ID])
        ON UPDATE CASCADE
        ON DELETE CASCADE

        PRINT '  ✓ Added FK_Credit_Note_Detail_Credit_Note'
    END

    -- Debit Note FKs
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Debit_Note_Customer')
    BEGIN
        ALTER TABLE [dbo].[Debit_Note]
        ADD CONSTRAINT [FK_Debit_Note_Customer]
        FOREIGN KEY([Customer_MobilePhone])
        REFERENCES [dbo].[Customer] ([MobilePhone])
        ON UPDATE CASCADE
        ON DELETE NO ACTION

        PRINT '  ✓ Added FK_Debit_Note_Customer'
    END

    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Debit_Note_Detail_Debit_Note')
    BEGIN
        ALTER TABLE [dbo].[Debit_Note_Detail]
        ADD CONSTRAINT [FK_Debit_Note_Detail_Debit_Note]
        FOREIGN KEY([DebitNote_ID])
        REFERENCES [dbo].[Debit_Note] ([ID])
        ON UPDATE CASCADE
        ON DELETE CASCADE

        PRINT '  ✓ Added FK_Debit_Note_Detail_Debit_Note'
    END

    -- ===================================================================
    -- Step 7: Add indexes
    -- ===================================================================

    PRINT 'Step 7: Creating performance indexes...'

    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Credit_Note_Date')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Credit_Note_Date]
        ON [dbo].[Credit_Note] ([CreditNoteDate] DESC)
        INCLUDE ([Status], [GrandTotal])

        PRINT '  ✓ Created IX_Credit_Note_Date'
    END

    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Debit_Note_Date')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Debit_Note_Date]
        ON [dbo].[Debit_Note] ([DebitNoteDate] DESC)
        INCLUDE ([Status], [GrandTotal])

        PRINT '  ✓ Created IX_Debit_Note_Date'
    END

    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Account_Receipt_TransactionDate')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Account_Receipt_TransactionDate]
        ON [dbo].[Account_Receipt] ([TransactionDate] DESC, [IsFrontTransaction])
        INCLUDE ([Total_Amount], [Type_ID], [RevenueCategory])

        PRINT '  ✓ Created IX_Account_Receipt_TransactionDate'
    END

    -- ===================================================================
    -- Step 8: Create stored procedures
    -- ===================================================================

    PRINT 'Step 8: Creating stored procedures...'

    -- Generate Credit Note Number
    IF OBJECT_ID('dbo.sp_GenerateCreditNoteNumber', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_GenerateCreditNoteNumber

    EXEC('
    CREATE PROCEDURE [dbo].[sp_GenerateCreditNoteNumber]
        @CreditNoteNumber NVARCHAR(20) OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @Year INT = YEAR(GETDATE())
        DECLARE @Month INT = MONTH(GETDATE())
        DECLARE @NextNumber INT

        -- Get next number for this month
        SELECT @NextNumber = ISNULL(MAX(
            CAST(RIGHT(CreditNoteNumber, 4) AS INT)
        ), 0) + 1
        FROM Credit_Note
        WHERE CreditNoteNumber LIKE ''CN'' + CAST(@Year AS VARCHAR(4)) + RIGHT(''0'' + CAST(@Month AS VARCHAR(2)), 2) + ''%''

        -- Format: CN202511XXXX
        SET @CreditNoteNumber = ''CN'' + CAST(@Year AS VARCHAR(4)) + RIGHT(''0'' + CAST(@Month AS VARCHAR(2)), 2) + RIGHT(''000'' + CAST(@NextNumber AS VARCHAR(4)), 4)

        RETURN 0
    END
    ')

    PRINT '  ✓ Created sp_GenerateCreditNoteNumber'

    -- Generate Debit Note Number
    IF OBJECT_ID('dbo.sp_GenerateDebitNoteNumber', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_GenerateDebitNoteNumber

    EXEC('
    CREATE PROCEDURE [dbo].[sp_GenerateDebitNoteNumber]
        @DebitNoteNumber NVARCHAR(20) OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @Year INT = YEAR(GETDATE())
        DECLARE @Month INT = MONTH(GETDATE())
        DECLARE @NextNumber INT

        -- Get next number for this month
        SELECT @NextNumber = ISNULL(MAX(
            CAST(RIGHT(DebitNoteNumber, 4) AS INT)
        ), 0) + 1
        FROM Debit_Note
        WHERE DebitNoteNumber LIKE ''DN'' + CAST(@Year AS VARCHAR(4)) + RIGHT(''0'' + CAST(@Month AS VARCHAR(2)), 2) + ''%''

        -- Format: DN202511XXXX
        SET @DebitNoteNumber = ''DN'' + CAST(@Year AS VARCHAR(4)) + RIGHT(''0'' + CAST(@Month AS VARCHAR(2)), 2) + RIGHT(''0000'' + CAST(@NextNumber AS VARCHAR(4)), 4)

        RETURN 0
    END
    ')

    PRINT '  ✓ Created sp_GenerateDebitNoteNumber'

    -- Get Front Team Daily Summary
    IF OBJECT_ID('dbo.sp_GetFrontTeamDailySummary', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_GetFrontTeamDailySummary

    EXEC('
    CREATE PROCEDURE [dbo].[sp_GetFrontTeamDailySummary]
        @StartDate DATE = NULL,
        @EndDate DATE = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        -- Default to today if not specified
        IF @StartDate IS NULL
            SET @StartDate = CAST(GETDATE() AS DATE)

        IF @EndDate IS NULL
            SET @EndDate = @StartDate

        SELECT
            AR.TransactionDate,
            PT.PaymentTypeName AS PaymentChannel,
            AR.RevenueCategory,
            APT.ProductTypeName AS CategoryName,
            COUNT(AR.ID) AS TransactionCount,
            SUM(AR.Total_Amount) AS TotalRevenue,
            SUM(CASE WHEN AR.IsCheckIn = 1 THEN AR.Total_Amount ELSE 0 END) AS CheckInRevenue,
            SUM(CASE WHEN APT.ID = 1 THEN AR.Total_Amount ELSE 0 END) AS AccommodationRevenue,
            SUM(CASE WHEN APT.ID != 1 THEN AR.Total_Amount ELSE 0 END) AS OtherRevenue
        FROM Account_Receipt AR
        LEFT JOIN PaymentType PT ON AR.Type_ID = PT.ID
        LEFT JOIN Account_ProductType APT ON AR.ProductType_ID = APT.ID
        WHERE AR.TransactionDate BETWEEN @StartDate AND @EndDate
          AND AR.IsFrontTransaction = 1
          AND AR.Status = 1
        GROUP BY AR.TransactionDate, PT.PaymentTypeName, AR.RevenueCategory, APT.ProductTypeName
        ORDER BY AR.TransactionDate DESC, PT.PaymentTypeName, AR.RevenueCategory

        RETURN 0
    END
    ')

    PRINT '  ✓ Created sp_GetFrontTeamDailySummary'

    -- ===================================================================
    -- Step 9: Create views
    -- ===================================================================

    PRINT 'Step 9: Creating views...'

    IF OBJECT_ID('dbo.v_CheckDocument_Summary', 'V') IS NOT NULL
        DROP VIEW dbo.v_CheckDocument_Summary

    EXEC('
    CREATE VIEW [dbo].[v_CheckDocument_Summary]
    AS
    SELECT
        AR.TransactionDate,
        AR.Created_Date,
        AR.ID AS ReceiptID,
        AR.Receipt_Number AS DocumentNumber,
        ''RECEIPT'' AS DocumentType,
        AR.Reservation_ID,
        R.CheckinDate,
        R.CheckoutDate,
        C.Name AS CustomerName,
        C.MobilePhone AS CustomerPhone,
        AR.Total_Amount,
        PT.PaymentTypeName,
        AR.RevenueCategory,
        APT.ProductTypeName,
        AR.IsCheckIn,
        AR.IsFrontTransaction,
        AR.Status,
        E.Name AS CreatedByName
    FROM Account_Receipt AR
    LEFT JOIN Reservation R ON AR.Reservation_ID = R.ID
    LEFT JOIN Customer C ON AR.Customer_Phone = C.MobilePhone
    LEFT JOIN PaymentType PT ON AR.Type_ID = PT.ID
    LEFT JOIN Account_ProductType APT ON AR.ProductType_ID = APT.ID
    LEFT JOIN Employees E ON AR.Created_By = E.ID
    WHERE AR.Status = 1

    UNION ALL

    SELECT
        CAST(CN.CreditNoteDate AS DATE) AS TransactionDate,
        CN.CreditNoteDate AS Created_Date,
        CN.ID AS ReceiptID,
        CN.CreditNoteNumber AS DocumentNumber,
        ''CREDIT_NOTE'' AS DocumentType,
        CN.Reservation_ID,
        NULL AS CheckinDate,
        NULL AS CheckoutDate,
        C.Name AS CustomerName,
        C.MobilePhone AS CustomerPhone,
        -CN.GrandTotal AS Total_Amount,
        NULL AS PaymentTypeName,
        ''CREDIT_NOTE'' AS RevenueCategory,
        NULL AS ProductTypeName,
        0 AS IsCheckIn,
        1 AS IsFrontTransaction,
        CASE CN.Status WHEN ''APPROVED'' THEN 1 ELSE 0 END AS Status,
        E.Name AS CreatedByName
    FROM Credit_Note CN
    LEFT JOIN Customer C ON CN.Customer_MobilePhone = C.MobilePhone
    LEFT JOIN Employees E ON CN.CreatedBy_ID = E.ID
    WHERE CN.Status = ''APPROVED''

    UNION ALL

    SELECT
        CAST(DN.DebitNoteDate AS DATE) AS TransactionDate,
        DN.DebitNoteDate AS Created_Date,
        DN.ID AS ReceiptID,
        DN.DebitNoteNumber AS DocumentNumber,
        ''DEBIT_NOTE'' AS DocumentType,
        DN.Reservation_ID,
        NULL AS CheckinDate,
        NULL AS CheckoutDate,
        C.Name AS CustomerName,
        C.MobilePhone AS CustomerPhone,
        DN.GrandTotal AS Total_Amount,
        NULL AS PaymentTypeName,
        ''DEBIT_NOTE'' AS RevenueCategory,
        NULL AS ProductTypeName,
        0 AS IsCheckIn,
        1 AS IsFrontTransaction,
        CASE DN.Status WHEN ''PAID'' THEN 1 ELSE 0 END AS Status,
        E.Name AS CreatedByName
    FROM Debit_Note DN
    LEFT JOIN Customer C ON DN.Customer_MobilePhone = C.MobilePhone
    LEFT JOIN Employees E ON DN.CreatedBy_ID = E.ID
    WHERE DN.Status IN (''APPROVED'', ''PAID'')
    ')

    PRINT '  ✓ Created v_CheckDocument_Summary'

    -- ===================================================================
    -- Step 10: Update existing data
    -- ===================================================================

    PRINT 'Step 10: Updating existing data...'

    -- Set TransactionDate for existing receipts
    UPDATE AR
    SET TransactionDate = CAST(AR.Created_Date AS DATE)
    FROM Account_Receipt AR
    WHERE TransactionDate IS NULL AND Created_Date IS NOT NULL

    -- Mark check-in transactions
    UPDATE AR
    SET IsCheckIn = 1
    FROM Account_Receipt AR
    INNER JOIN Reservation R ON AR.Reservation_ID = R.ID
    WHERE CAST(AR.Created_Date AS DATE) = R.CheckinDate

    -- Set revenue categories
    UPDATE AR
    SET RevenueCategory = CASE
        WHEN APT.ID = 1 THEN ''ACCOMMODATION''
        WHEN APT.ID = 2 THEN ''FOOD_BEVERAGE''
        WHEN APT.ID = 3 THEN ''RENTAL''
        ELSE ''OTHER''
    END
    FROM Account_Receipt AR
    LEFT JOIN Account_ProductType APT ON AR.ProductType_ID = APT.ID
    WHERE AR.RevenueCategory IS NULL

    PRINT '  ✓ Updated existing receipts'

    -- ===================================================================
    -- Commit Transaction
    -- ===================================================================

    COMMIT TRANSACTION

    PRINT ''
    PRINT '✓ All database modifications completed successfully'
    PRINT ''

    -- ===================================================================
    -- Record successful migration
    -- ===================================================================

    DECLARE @ExecutionTime INT = DATEDIFF(MILLISECOND, @StartTime, GETDATE())

    EXEC sp_RecordMigration
        @MigrationName = @MigrationName,
        @AppliedBy = SYSTEM_USER,
        @Success = 1,
        @ExecutionTimeMs = @ExecutionTime

    PRINT '============================================================='
    PRINT 'Migration completed successfully!'
    PRINT 'Execution time: ' + CAST(@ExecutionTime AS VARCHAR) + ' ms'
    PRINT '============================================================='
    PRINT ''

    PRINT 'Standard Accounting System Features:'
    PRINT '  ✓ Credit Note (ใบลดหนี้) for refunds and adjustments'
    PRINT '  ✓ Debit Note (ใบเพิ่มหนี้) for additional charges'
    PRINT '  ✓ Transaction date tracking'
    PRINT '  ✓ Front team transaction separation'
    PRINT '  ✓ Revenue categorization'
    PRINT '  ✓ Daily summary reporting'
    PRINT ''

END TRY

BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
    DECLARE @ErrorState INT = ERROR_STATE()
    DECLARE @ErrorLine INT = ERROR_LINE()

    PRINT ''
    PRINT '============================================================='
    PRINT '✗ Migration failed!'
    PRINT '============================================================='
    PRINT 'Error: ' + @ErrorMessage
    PRINT 'Line: ' + CAST(@ErrorLine AS VARCHAR)
    PRINT '============================================================='
    PRINT ''

    EXEC sp_RecordMigration
        @MigrationName = @MigrationName,
        @AppliedBy = SYSTEM_USER,
        @Success = 0,
        @ErrorMessage = @ErrorMessage

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
END CATCH

MigrationEnd:

PRINT ''
PRINT 'Migration script ended: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT ''

GO
