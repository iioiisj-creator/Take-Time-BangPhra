/*==============================================================
  Migration: Add PMS Guest Folio System

  Description:
  - Add Guest Folio (Guest Bill) system for PMS
  - Track all charges and payments per reservation
  - Support check-in/check-out with balance validation
  - Enable "post to room" functionality

  Author: Claude
  Created: 2025-11-03
==============================================================*/

USE [Taketime]
GO

-- ===================================================================
-- Check if migration was already applied
-- ===================================================================
DECLARE @MigrationName NVARCHAR(255) = 'Add_PMS_Guest_Folio_System'
DECLARE @IsApplied TABLE (IsApplied INT)

INSERT INTO @IsApplied
EXEC sp_IsMigrationApplied @MigrationName

IF EXISTS (SELECT 1 FROM @IsApplied WHERE IsApplied = 1)
BEGIN
    PRINT 'Migration already applied: ' + @MigrationName
    RETURN
END
GO

PRINT '============================================================='
PRINT 'Applying Migration: Add PMS Guest Folio System'
PRINT '============================================================='
GO

-- ===================================================================
-- STEP 1: Create Guest_Folio table (Guest Bill)
-- ===================================================================
PRINT 'Step 1: Creating Guest_Folio table...'
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Guest_Folio]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Guest_Folio](
        [ID] [bigint] IDENTITY(1,1) NOT NULL,
        [Reservation_ID] [bigint] NOT NULL,
        [FolioNumber] [nvarchar](20) NOT NULL,
        [Created_Date] [datetime] NOT NULL,
        [Status] [nvarchar](20) NOT NULL,
        [TotalCharges] [decimal](18, 2) NOT NULL,
        [TotalPayments] [decimal](18, 2) NOT NULL,
        [Balance] AS ([TotalCharges] - [TotalPayments]) PERSISTED,
        [Notes] [ntext] NULL,
     CONSTRAINT [PK_Guest_Folio] PRIMARY KEY CLUSTERED ([ID] ASC),
     CONSTRAINT [UQ_Guest_Folio_Number] UNIQUE NONCLUSTERED ([FolioNumber] ASC)
    )

    ALTER TABLE [dbo].[Guest_Folio] ADD CONSTRAINT [DF_Guest_Folio_Created_Date] DEFAULT (GETDATE()) FOR [Created_Date]
    ALTER TABLE [dbo].[Guest_Folio] ADD CONSTRAINT [DF_Guest_Folio_Status] DEFAULT ('OPEN') FOR [Status]
    ALTER TABLE [dbo].[Guest_Folio] ADD CONSTRAINT [DF_Guest_Folio_TotalCharges] DEFAULT ((0)) FOR [TotalCharges]
    ALTER TABLE [dbo].[Guest_Folio] ADD CONSTRAINT [DF_Guest_Folio_TotalPayments] DEFAULT ((0)) FOR [TotalPayments]

    PRINT '  ✓ Created table: Guest_Folio'
END
GO

-- ===================================================================
-- STEP 2: Create Folio_Transaction table
-- ===================================================================
PRINT 'Step 2: Creating Folio_Transaction table...'
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Folio_Transaction]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Folio_Transaction](
        [ID] [bigint] IDENTITY(1,1) NOT NULL,
        [Folio_ID] [bigint] NOT NULL,
        [TransactionDate] [datetime] NOT NULL,
        [TransactionType] [nvarchar](20) NOT NULL,
        [ProductType_ID] [tinyint] NULL,
        [Product_ID] [int] NULL,
        [Description] [nvarchar](500) NOT NULL,
        [Amount] [decimal](18, 2) NOT NULL,
        [Quantity] [decimal](10, 2) NOT NULL,
        [TotalAmount] AS ([Amount] * [Quantity]) PERSISTED,
        [Reference_Number] [nvarchar](50) NULL,
        [Created_By_ID] [smallint] NULL,
        [Status] [bit] NOT NULL,
     CONSTRAINT [PK_Folio_Transaction] PRIMARY KEY CLUSTERED ([ID] ASC)
    )

    ALTER TABLE [dbo].[Folio_Transaction] ADD CONSTRAINT [DF_Folio_Transaction_TransactionDate] DEFAULT (GETDATE()) FOR [TransactionDate]
    ALTER TABLE [dbo].[Folio_Transaction] ADD CONSTRAINT [DF_Folio_Transaction_Quantity] DEFAULT ((1)) FOR [Quantity]
    ALTER TABLE [dbo].[Folio_Transaction] ADD CONSTRAINT [DF_Folio_Transaction_Status] DEFAULT ((1)) FOR [Status]

    PRINT '  ✓ Created table: Folio_Transaction'
END
GO

-- ===================================================================
-- STEP 3: Update Reservation table with check-in/out fields
-- ===================================================================
PRINT 'Step 3: Updating Reservation table...'
GO

-- ActualCheckInDate
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Reservation]')
    AND name = 'ActualCheckInDate'
)
BEGIN
    ALTER TABLE [dbo].[Reservation]
    ADD ActualCheckInDate DATETIME NULL

    PRINT '  ✓ Added column: ActualCheckInDate'
END

-- ActualCheckInBy_ID
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Reservation]')
    AND name = 'ActualCheckInBy_ID'
)
BEGIN
    ALTER TABLE [dbo].[Reservation]
    ADD ActualCheckInBy_ID SMALLINT NULL

    PRINT '  ✓ Added column: ActualCheckInBy_ID'
END

-- ActualCheckOutDate
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Reservation]')
    AND name = 'ActualCheckOutDate'
)
BEGIN
    ALTER TABLE [dbo].[Reservation]
    ADD ActualCheckOutDate DATETIME NULL

    PRINT '  ✓ Added column: ActualCheckOutDate'
END

-- ActualCheckOutBy_ID
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Reservation]')
    AND name = 'ActualCheckOutBy_ID'
)
BEGIN
    ALTER TABLE [dbo].[Reservation]
    ADD ActualCheckOutBy_ID SMALLINT NULL

    PRINT '  ✓ Added column: ActualCheckOutBy_ID'
END

-- Folio_ID
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Reservation]')
    AND name = 'Folio_ID'
)
BEGIN
    ALTER TABLE [dbo].[Reservation]
    ADD Folio_ID BIGINT NULL

    PRINT '  ✓ Added column: Folio_ID'
END

-- HasOutstandingBalance
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Reservation]')
    AND name = 'HasOutstandingBalance'
)
BEGIN
    ALTER TABLE [dbo].[Reservation]
    ADD HasOutstandingBalance BIT DEFAULT 0

    PRINT '  ✓ Added column: HasOutstandingBalance'
END
GO

-- ===================================================================
-- STEP 4: Create stored procedure to generate folio number
-- ===================================================================
PRINT 'Step 4: Creating stored procedure for folio number...'
GO

IF OBJECT_ID('dbo.sp_GenerateFolioNumber', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GenerateFolioNumber
GO

CREATE PROCEDURE [dbo].[sp_GenerateFolioNumber]
    @ReservationID BIGINT,
    @FolioNumber NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Year VARCHAR(4) = CAST(YEAR(GETDATE()) AS VARCHAR(4))
    DECLARE @Month VARCHAR(2) = RIGHT('0' + CAST(MONTH(GETDATE()) AS VARCHAR(2)), 2)
    DECLARE @Sequence INT

    -- Get next sequence for this month
    SELECT @Sequence = ISNULL(MAX(CAST(RIGHT(FolioNumber, 4) AS INT)), 0) + 1
    FROM Guest_Folio
    WHERE FolioNumber LIKE 'F' + @Year + @Month + '%'

    SET @FolioNumber = 'F' + @Year + @Month + RIGHT('0000' + CAST(@Sequence AS VARCHAR(4)), 4)
END
GO

PRINT '  ✓ Created procedure: sp_GenerateFolioNumber'
GO

-- ===================================================================
-- STEP 5: Create stored procedure to create guest folio
-- ===================================================================
PRINT 'Step 5: Creating stored procedure to create folio...'
GO

IF OBJECT_ID('dbo.sp_CreateGuestFolio', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CreateGuestFolio
GO

CREATE PROCEDURE [dbo].[sp_CreateGuestFolio]
    @ReservationID BIGINT,
    @FolioID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FolioNumber NVARCHAR(20)

    -- Generate folio number
    EXEC sp_GenerateFolioNumber @ReservationID, @FolioNumber OUTPUT

    -- Create folio
    INSERT INTO Guest_Folio (Reservation_ID, FolioNumber, Status)
    VALUES (@ReservationID, @FolioNumber, 'OPEN')

    SET @FolioID = SCOPE_IDENTITY()

    -- Update reservation
    UPDATE Reservation
    SET Folio_ID = @FolioID
    WHERE ID = @ReservationID

    -- Return folio number
    SELECT @FolioNumber AS FolioNumber, @FolioID AS FolioID
END
GO

PRINT '  ✓ Created procedure: sp_CreateGuestFolio'
GO

-- ===================================================================
-- STEP 6: Create stored procedure to post charge to room
-- ===================================================================
PRINT 'Step 6: Creating stored procedure to post charge...'
GO

IF OBJECT_ID('dbo.sp_PostChargeToRoom', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_PostChargeToRoom
GO

CREATE PROCEDURE [dbo].[sp_PostChargeToRoom]
    @FolioID BIGINT,
    @ProductTypeID TINYINT,
    @ProductID INT,
    @Description NVARCHAR(500),
    @Amount DECIMAL(18,2),
    @Quantity DECIMAL(10,2) = 1,
    @ReferenceNumber NVARCHAR(50) = NULL,
    @CreatedByID SMALLINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION

    BEGIN TRY
        -- Insert transaction
        INSERT INTO Folio_Transaction
            (Folio_ID, TransactionType, ProductType_ID, Product_ID,
             Description, Amount, Quantity, Reference_Number, Created_By_ID)
        VALUES
            (@FolioID, 'CHARGE', @ProductTypeID, @ProductID,
             @Description, @Amount, @Quantity, @ReferenceNumber, @CreatedByID)

        -- Update folio totals
        UPDATE Guest_Folio
        SET TotalCharges = TotalCharges + (@Amount * @Quantity)
        WHERE ID = @FolioID

        -- Update reservation outstanding balance flag
        UPDATE Reservation
        SET HasOutstandingBalance = CASE
            WHEN (SELECT Balance FROM Guest_Folio WHERE ID = @FolioID) > 0 THEN 1
            ELSE 0
        END
        WHERE Folio_ID = @FolioID

        COMMIT TRANSACTION

        SELECT 'SUCCESS' AS Status, @FolioID AS FolioID
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage
    END CATCH
END
GO

PRINT '  ✓ Created procedure: sp_PostChargeToRoom'
GO

-- ===================================================================
-- STEP 7: Create stored procedure to post payment
-- ===================================================================
PRINT 'Step 7: Creating stored procedure to post payment...'
GO

IF OBJECT_ID('dbo.sp_PostPayment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_PostPayment
GO

CREATE PROCEDURE [dbo].[sp_PostPayment]
    @FolioID BIGINT,
    @Amount DECIMAL(18,2),
    @Description NVARCHAR(500),
    @ReferenceNumber NVARCHAR(50) = NULL,
    @CreatedByID SMALLINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION

    BEGIN TRY
        -- Insert payment transaction
        INSERT INTO Folio_Transaction
            (Folio_ID, TransactionType, Description, Amount, Quantity, Reference_Number, Created_By_ID)
        VALUES
            (@FolioID, 'PAYMENT', @Description, -@Amount, 1, @ReferenceNumber, @CreatedByID)

        -- Update folio totals
        UPDATE Guest_Folio
        SET TotalPayments = TotalPayments + @Amount
        WHERE ID = @FolioID

        -- Update reservation outstanding balance flag
        UPDATE Reservation
        SET HasOutstandingBalance = CASE
            WHEN (SELECT Balance FROM Guest_Folio WHERE ID = @FolioID) > 0 THEN 1
            ELSE 0
        END
        WHERE Folio_ID = @FolioID

        COMMIT TRANSACTION

        SELECT 'SUCCESS' AS Status, @FolioID AS FolioID
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage
    END CATCH
END
GO

PRINT '  ✓ Created procedure: sp_PostPayment'
GO

-- ===================================================================
-- STEP 8: Create view for folio summary
-- ===================================================================
PRINT 'Step 8: Creating folio summary view...'
GO

IF OBJECT_ID('dbo.v_GuestFolioSummary', 'V') IS NOT NULL
    DROP VIEW dbo.v_GuestFolioSummary
GO

CREATE VIEW [dbo].[v_GuestFolioSummary]
AS
SELECT
    GF.ID AS FolioID,
    GF.FolioNumber,
    GF.Reservation_ID,
    R.Customer_MobilePhone,
    C.Name AS CustomerName,
    R.CheckinDate,
    R.CheckoutDate,
    R.ActualCheckInDate,
    R.ActualCheckOutDate,
    GF.Created_Date AS FolioCreatedDate,
    GF.Status AS FolioStatus,
    GF.TotalCharges,
    GF.TotalPayments,
    GF.Balance,
    CASE
        WHEN GF.Balance > 0 THEN 'HAS_BALANCE'
        WHEN GF.Balance = 0 THEN 'SETTLED'
        ELSE 'OVERPAID'
    END AS BalanceStatus
FROM Guest_Folio GF
INNER JOIN Reservation R ON GF.Reservation_ID = R.ID
INNER JOIN Customer C ON R.Customer_MobilePhone = C.MobilePhone
GO

PRINT '  ✓ Created view: v_GuestFolioSummary'
GO

-- ===================================================================
-- STEP 9: Create indexes for performance
-- ===================================================================
PRINT 'Step 9: Creating indexes...'
GO

-- Index on Reservation_ID for fast lookup
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Guest_Folio_Reservation_ID')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Guest_Folio_Reservation_ID
    ON Guest_Folio (Reservation_ID)
    INCLUDE (FolioNumber, Status, Balance)

    PRINT '  ✓ Created index: IX_Guest_Folio_Reservation_ID'
END

-- Index on Folio_ID for transactions
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Folio_Transaction_Folio_ID')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Folio_Transaction_Folio_ID
    ON Folio_Transaction (Folio_ID, TransactionDate)
    INCLUDE (TransactionType, Amount, Description)

    PRINT '  ✓ Created index: IX_Folio_Transaction_Folio_ID'
END
GO

-- ===================================================================
-- Record this migration
-- ===================================================================
EXEC sp_RecordMigration
    @MigrationName = 'Add_PMS_Guest_Folio_System',
    @AppliedBy = SYSTEM_USER,
    @Success = 1
GO

PRINT ''
PRINT '============================================================='
PRINT 'Migration completed successfully!'
PRINT '============================================================='
PRINT ''
PRINT 'Summary:'
PRINT '  ✓ Guest_Folio table created'
PRINT '  ✓ Folio_Transaction table created'
PRINT '  ✓ Reservation table updated with check-in/out fields'
PRINT '  ✓ Stored procedures created:'
PRINT '    - sp_GenerateFolioNumber'
PRINT '    - sp_CreateGuestFolio'
PRINT '    - sp_PostChargeToRoom'
PRINT '    - sp_PostPayment'
PRINT '  ✓ Views created: v_GuestFolioSummary'
PRINT '  ✓ Indexes created for performance'
PRINT ''
PRINT 'Next steps:'
PRINT '  1. Test folio creation'
PRINT '  2. Test posting charges'
PRINT '  3. Implement UI for guest folio management'
PRINT ''
GO

-- ===================================================================
-- Optional: Sample queries to test
-- ===================================================================
/*
-- Create a test folio
DECLARE @FolioID BIGINT
EXEC sp_CreateGuestFolio @ReservationID = 1, @FolioID = @FolioID OUTPUT
SELECT @FolioID AS NewFolioID

-- Post a charge
EXEC sp_PostChargeToRoom
    @FolioID = 1,
    @ProductTypeID = 3,
    @ProductID = 1,
    @Description = N'หมูกระทะ',
    @Amount = 499,
    @Quantity = 1

-- Post a payment
EXEC sp_PostPayment
    @FolioID = 1,
    @Amount = 500,
    @Description = N'ชำระเงินสด'

-- View folio summary
SELECT * FROM v_GuestFolioSummary
*/

-- ===================================================================
-- Rollback script (commented out for safety)
-- ===================================================================
/*
-- Drop views
DROP VIEW IF EXISTS v_GuestFolioSummary

-- Drop stored procedures
DROP PROCEDURE IF EXISTS sp_PostPayment
DROP PROCEDURE IF EXISTS sp_PostChargeToRoom
DROP PROCEDURE IF EXISTS sp_CreateGuestFolio
DROP PROCEDURE IF EXISTS sp_GenerateFolioNumber

-- Drop indexes
DROP INDEX IF EXISTS IX_Folio_Transaction_Folio_ID ON Folio_Transaction
DROP INDEX IF EXISTS IX_Guest_Folio_Reservation_ID ON Guest_Folio

-- Remove columns from Reservation
ALTER TABLE Reservation DROP COLUMN IF EXISTS HasOutstandingBalance
ALTER TABLE Reservation DROP COLUMN IF EXISTS Folio_ID
ALTER TABLE Reservation DROP COLUMN IF EXISTS ActualCheckOutBy_ID
ALTER TABLE Reservation DROP COLUMN IF EXISTS ActualCheckOutDate
ALTER TABLE Reservation DROP COLUMN IF EXISTS ActualCheckInBy_ID
ALTER TABLE Reservation DROP COLUMN IF EXISTS ActualCheckInDate

-- Drop tables
DROP TABLE IF EXISTS Folio_Transaction
DROP TABLE IF EXISTS Guest_Folio

-- Remove migration record
DELETE FROM Database_Migrations WHERE MigrationName = 'Add_PMS_Guest_Folio_System'
*/
