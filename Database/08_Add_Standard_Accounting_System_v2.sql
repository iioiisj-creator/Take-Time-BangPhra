/*==============================================================
  Migration: 08_Add_Standard_Accounting_System_v2

  Purpose:
  - Add revenue category tracking to Account_Receipt
  - Add payment channel tracking
  - Add transaction date tracking
  - Create views and stored procedures for accounting reports

  Note: This migration checks if columns already exist before adding them

  Author: Claude
  Date: 2025-11-04
  Dependencies: 07_Add_Customer_Management_Enhancement_v2
==============================================================*/

USE [Taketime]
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @MigrationName NVARCHAR(255) = '08_Add_Standard_Accounting_System_v2'
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
    PRINT 'Migration already applied: ' + @MigrationName
    PRINT 'Skipping execution'
    PRINT ''
    GOTO MigrationEnd
END

-- ===================================================================
-- Pre-flight checks
-- ===================================================================

PRINT 'Running pre-flight checks...'
PRINT ''

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND type in (N'U'))
BEGIN
    RAISERROR('Account_Receipt table does not exist. Cannot proceed.', 16, 1)
    GOTO MigrationEnd
END

PRINT 'Account_Receipt table exists'
PRINT ''

-- ===================================================================
-- Begin Transaction
-- ===================================================================

BEGIN TRANSACTION

BEGIN TRY

    PRINT 'Starting database modifications...'
    PRINT ''

    -- ===================================================================
    -- Step 1: Add columns to Account_Receipt
    -- ===================================================================

    PRINT 'Step 1: Adding columns to Account_Receipt...'
    PRINT ''

    -- RevenueCategory
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND name = 'RevenueCategory')
    BEGIN
        ALTER TABLE [dbo].[Account_Receipt]
        ADD [RevenueCategory] [nvarchar](50) NULL

        PRINT '  Added RevenueCategory column'
    END
    ELSE
    BEGIN
        PRINT '  RevenueCategory column already exists'
    END

    -- PaymentChannel
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND name = 'PaymentChannel')
    BEGIN
        ALTER TABLE [dbo].[Account_Receipt]
        ADD [PaymentChannel] [nvarchar](50) NULL

        PRINT '  Added PaymentChannel column'
    END
    ELSE
    BEGIN
        PRINT '  PaymentChannel column already exists'
    END

    -- TransactionDate
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND name = 'TransactionDate')
    BEGIN
        ALTER TABLE [dbo].[Account_Receipt]
        ADD [TransactionDate] [date] NULL

        PRINT '  Added TransactionDate column'
    END
    ELSE
    BEGIN
        PRINT '  TransactionDate column already exists'
    END

    -- ProductType_ID
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND name = 'ProductType_ID')
    BEGIN
        ALTER TABLE [dbo].[Account_Receipt]
        ADD [ProductType_ID] [tinyint] NULL

        PRINT '  Added ProductType_ID column'
    END
    ELSE
    BEGIN
        PRINT '  ProductType_ID column already exists'
    END

    -- IsFrontTransaction (for Front Desk sales vs Check-in)
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Account_Receipt]') AND name = 'IsFrontTransaction')
    BEGIN
        ALTER TABLE [dbo].[Account_Receipt]
        ADD [IsFrontTransaction] [bit] NULL DEFAULT 0

        PRINT '  Added IsFrontTransaction column'
    END
    ELSE
    BEGIN
        PRINT '  IsFrontTransaction column already exists'
    END

    PRINT ''

    -- ===================================================================
    -- Step 2: Create indexes
    -- ===================================================================

    PRINT 'Step 2: Creating indexes...'

    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Account_Receipt_RevenueCategory')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Account_Receipt_RevenueCategory]
        ON [dbo].[Account_Receipt] ([RevenueCategory], [Created_Date])
        WHERE [RevenueCategory] IS NOT NULL

        PRINT '  Created IX_Account_Receipt_RevenueCategory'
    END
    ELSE
    BEGIN
        PRINT '  IX_Account_Receipt_RevenueCategory already exists'
    END

    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Account_Receipt_PaymentChannel')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Account_Receipt_PaymentChannel]
        ON [dbo].[Account_Receipt] ([PaymentChannel], [Created_Date])
        WHERE [PaymentChannel] IS NOT NULL

        PRINT '  Created IX_Account_Receipt_PaymentChannel'
    END
    ELSE
    BEGIN
        PRINT '  IX_Account_Receipt_PaymentChannel already exists'
    END

    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Account_Receipt_TransactionDate')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Account_Receipt_TransactionDate]
        ON [dbo].[Account_Receipt] ([TransactionDate] DESC)
        WHERE [TransactionDate] IS NOT NULL

        PRINT '  Created IX_Account_Receipt_TransactionDate'
    END
    ELSE
    BEGIN
        PRINT '  IX_Account_Receipt_TransactionDate already exists'
    END

    PRINT ''

    -- ===================================================================
    -- Step 3: Create view for revenue summary
    -- ===================================================================

    PRINT 'Step 3: Creating views...'

    IF OBJECT_ID('dbo.v_RevenueSummary', 'V') IS NOT NULL
        DROP VIEW dbo.v_RevenueSummary

    EXEC('
    CREATE VIEW [dbo].[v_RevenueSummary]
    AS
    SELECT
        AR.ID,
        AR.Created_Date,
        AR.TransactionDate,
        AR.Total_Amount,
        AR.RevenueCategory,
        AR.PaymentChannel,
        AR.Paid_Type,
        AR.IsFrontTransaction,
        C.Name AS CustomerName,
        C.MobilePhone,
        R.CheckinDate,
        R.CheckoutDate,
        CASE
            WHEN AR.IsFrontTransaction = 1 THEN ''หน้าเคาน์เตอร์''
            WHEN AR.Reservation_ID IS NOT NULL THEN ''เช็คอิน''
            ELSE ''อื่นๆ''
        END AS TransactionType
    FROM Account_Receipt AR
    LEFT JOIN Customer C ON AR.Customer_ID = C.ID
    LEFT JOIN Reservation R ON AR.Reservation_ID = R.ID
    WHERE AR.Status NOT IN (N''ยกเลิก'', N''ยกเลิกคืนเงิน'')
    ')

    PRINT '  Created v_RevenueSummary'

    PRINT ''

    -- ===================================================================
    -- Step 4: Create stored procedures
    -- ===================================================================

    PRINT 'Step 4: Creating stored procedures...'

    -- Procedure: Get revenue by category
    IF OBJECT_ID('dbo.sp_GetRevenueSummaryByCategory', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_GetRevenueSummaryByCategory

    EXEC('
    CREATE PROCEDURE [dbo].[sp_GetRevenueSummaryByCategory]
        @StartDate DATE,
        @EndDate DATE
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            ISNULL(RevenueCategory, ''ไม่ระบุ'') AS Category,
            COUNT(*) AS TransactionCount,
            SUM(Total_Amount) AS TotalRevenue,
            AVG(Total_Amount) AS AverageRevenue
        FROM Account_Receipt
        WHERE TransactionDate BETWEEN @StartDate AND @EndDate
          AND Status NOT IN (N''ยกเลิก'', N''ยกเลิกคืนเงิน'')
        GROUP BY RevenueCategory
        ORDER BY SUM(Total_Amount) DESC
    END
    ')

    PRINT '  Created sp_GetRevenueSummaryByCategory'

    -- Procedure: Get revenue by payment channel
    IF OBJECT_ID('dbo.sp_GetRevenueSummaryByPaymentChannel', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_GetRevenueSummaryByPaymentChannel

    EXEC('
    CREATE PROCEDURE [dbo].[sp_GetRevenueSummaryByPaymentChannel]
        @StartDate DATE,
        @EndDate DATE
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            ISNULL(PaymentChannel, ISNULL(Paid_Type, ''ไม่ระบุ'')) AS Channel,
            COUNT(*) AS TransactionCount,
            SUM(Total_Amount) AS TotalRevenue,
            AVG(Total_Amount) AS AverageRevenue
        FROM Account_Receipt
        WHERE TransactionDate BETWEEN @StartDate AND @EndDate
          AND Status NOT IN (N''ยกเลิก'', N''ยกเลิกคืนเงิน'')
        GROUP BY PaymentChannel, Paid_Type
        ORDER BY SUM(Total_Amount) DESC
    END
    ')

    PRINT '  Created sp_GetRevenueSummaryByPaymentChannel'

    -- Procedure: Get daily revenue summary
    IF OBJECT_ID('dbo.sp_GetDailyRevenueSummary', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_GetDailyRevenueSummary

    EXEC('
    CREATE PROCEDURE [dbo].[sp_GetDailyRevenueSummary]
        @StartDate DATE,
        @EndDate DATE
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            TransactionDate,
            COUNT(*) AS TransactionCount,
            SUM(CASE WHEN IsFrontTransaction = 1 THEN Total_Amount ELSE 0 END) AS FrontDeskRevenue,
            SUM(CASE WHEN Reservation_ID IS NOT NULL THEN Total_Amount ELSE 0 END) AS CheckInRevenue,
            SUM(Total_Amount) AS TotalRevenue
        FROM Account_Receipt
        WHERE TransactionDate BETWEEN @StartDate AND @EndDate
          AND Status NOT IN (N''ยกเลิก'', N''ยกเลิกคืนเงิน'')
        GROUP BY TransactionDate
        ORDER BY TransactionDate DESC
    END
    ')

    PRINT '  Created sp_GetDailyRevenueSummary'

    PRINT ''

    -- ===================================================================
    -- Step 5: Update existing data
    -- ===================================================================

    PRINT 'Step 5: Updating existing data...'

    -- Set TransactionDate from Created_Date
    DECLARE @UpdatedRows INT = 0

    UPDATE Account_Receipt
    SET TransactionDate = CAST(Created_Date AS DATE)
    WHERE TransactionDate IS NULL AND Created_Date IS NOT NULL

    SET @UpdatedRows = @@ROWCOUNT
    PRINT '  Updated TransactionDate for ' + CAST(@UpdatedRows AS VARCHAR) + ' records'

    -- Set PaymentChannel from Paid_Type
    UPDATE Account_Receipt
    SET PaymentChannel = Paid_Type
    WHERE PaymentChannel IS NULL AND Paid_Type IS NOT NULL

    PRINT '  Updated PaymentChannel from Paid_Type'

    -- Set RevenueCategory based on Reservation
    UPDATE Account_Receipt
    SET RevenueCategory = CASE
        WHEN Reservation_ID IS NOT NULL THEN 'ACCOMMODATION'
        ELSE 'OTHER'
    END
    WHERE RevenueCategory IS NULL

    PRINT '  Updated RevenueCategory'

    -- Set IsFrontTransaction
    UPDATE Account_Receipt
    SET IsFrontTransaction = CASE
        WHEN Reservation_ID IS NULL THEN 1
        ELSE 0
    END
    WHERE IsFrontTransaction IS NULL

    PRINT '  Updated IsFrontTransaction'

    PRINT ''

    -- ===================================================================
    -- Commit Transaction
    -- ===================================================================

    COMMIT TRANSACTION

    PRINT '============================================================='
    PRINT 'Migration completed successfully!'
    DECLARE @ExecutionTime INT = DATEDIFF(MILLISECOND, @StartTime, GETDATE())
    PRINT 'Execution time: ' + CAST(@ExecutionTime AS VARCHAR) + ' ms'
    PRINT '============================================================='
    PRINT ''

    -- Record migration
    EXEC sp_RecordMigration
        @MigrationName = @MigrationName,
        @AppliedBy = SYSTEM_USER,
        @Success = 1,
        @ExecutionTimeMs = @ExecutionTime

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorLine INT = ERROR_LINE()

    PRINT ''
    PRINT '============================================================='
    PRINT 'Migration failed!'
    PRINT '============================================================='
    PRINT 'Error: ' + @ErrorMessage
    PRINT 'Line: ' + CAST(@ErrorLine AS VARCHAR)
    PRINT ''

    EXEC sp_RecordMigration
        @MigrationName = @MigrationName,
        @AppliedBy = SYSTEM_USER,
        @Success = 0,
        @ErrorMessage = @ErrorMessage

    THROW

END CATCH

MigrationEnd:

PRINT ''
PRINT '============================================================='
PRINT 'Migration script completed'
PRINT '============================================================='
