/*==============================================================
  Migration: 07_Add_Customer_Management_Enhancement_v2

  Purpose:
  - Add customer audit trail system
  - Ensure Admin.ID has Primary Key
  - Add indexes for performance
  - Create stored procedures for customer management

  Note: This migration checks if columns already exist before adding them
        Some columns (LastUpdated, CreatedDate, etc.) may already exist

  Author: Claude
  Date: 2025-11-04
  Dependencies: 00_Init_Migration_System
==============================================================*/

USE [Taketime]
GO

SET NOCOUNT ON;
SET XACT_ABORT ON; -- Rollback entire transaction on any error

DECLARE @MigrationName NVARCHAR(255) = '07_Add_Customer_Management_Enhancement_v2'
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

DECLARE @IsApplied BIT = 0

IF EXISTS (SELECT 1 FROM Database_Migrations WHERE MigrationName = @MigrationName AND Success = 1)
BEGIN
    SET @IsApplied = 1
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

-- Check if Customer table exists
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND type in (N'U'))
BEGIN
    RAISERROR('Customer table does not exist. Cannot proceed.', 16, 1)
    GOTO MigrationEnd
END

PRINT 'Customer table exists'

-- Check if Admin table exists
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Admin]') AND type in (N'U'))
BEGIN
    RAISERROR('Admin table does not exist. Cannot proceed.', 16, 1)
    GOTO MigrationEnd
END

PRINT 'Admin table exists'
PRINT ''

-- ===================================================================
-- Begin Transaction
-- ===================================================================

BEGIN TRANSACTION

BEGIN TRY

    PRINT 'Starting database modifications...'
    PRINT ''

    -- ===================================================================
    -- Step 1: Ensure Admin table has Primary Key
    -- ===================================================================

    PRINT 'Step 1: Ensuring Admin table has Primary Key...'

    IF NOT EXISTS (
        SELECT 1
        FROM sys.key_constraints
        WHERE type = 'PK'
          AND parent_object_id = OBJECT_ID('dbo.Admin')
    )
    BEGIN
        ALTER TABLE [dbo].[Admin]
        ADD CONSTRAINT [PK_Admin] PRIMARY KEY CLUSTERED ([ID] ASC)

        PRINT '  Added Primary Key to Admin.ID'
    END
    ELSE
    BEGIN
        PRINT '  Admin.ID already has a Primary Key'
    END

    PRINT ''

    -- ===================================================================
    -- Step 2: Create Customer_Audit_Log table
    -- ===================================================================

    PRINT 'Step 2: Creating Customer_Audit_Log table...'

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customer_Audit_Log]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[Customer_Audit_Log](
            [ID] [bigint] IDENTITY(1,1) NOT NULL,
            [Customer_ID] [bigint] NOT NULL,
            [Action] [nvarchar](20) NOT NULL, -- INSERT, UPDATE, DELETE, MERGE
            [FieldChanged] [nvarchar](100) NULL,
            [OldValue] [nvarchar](max) NULL,
            [NewValue] [nvarchar](max) NULL,
            [ChangeDate] [datetime] NOT NULL DEFAULT GETDATE(),
            [ChangedBy_ID] [smallint] NULL,
            [ChangedBy_Source] [nvarchar](100) NULL,
            [IPAddress] [nvarchar](50) NULL,
            [Notes] [nvarchar](500) NULL,
         CONSTRAINT [PK_Customer_Audit_Log] PRIMARY KEY CLUSTERED
        (
            [ID] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY]

        PRINT '  Created Customer_Audit_Log table'
    END
    ELSE
    BEGIN
        PRINT '  Customer_Audit_Log table already exists'
    END

    PRINT ''

    -- ===================================================================
    -- Step 3: Ensure Customer columns exist
    -- ===================================================================

    PRINT 'Step 3: Checking Customer table columns...'
    PRINT ''

    -- Check LastUpdated
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'LastUpdated')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [LastUpdated] [datetime] NULL DEFAULT GETDATE()
        PRINT '  Added LastUpdated column'
    END
    ELSE
    BEGIN
        PRINT '  LastUpdated column already exists'
    END

    -- Check LastUpdatedBy_ID
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'LastUpdatedBy_ID')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [LastUpdatedBy_ID] [smallint] NULL
        PRINT '  Added LastUpdatedBy_ID column'
    END
    ELSE
    BEGIN
        PRINT '  LastUpdatedBy_ID column already exists'
    END

    -- Check CreatedDate
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'CreatedDate')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [CreatedDate] [datetime] NULL DEFAULT GETDATE()
        PRINT '  Added CreatedDate column'
    END
    ELSE
    BEGIN
        PRINT '  CreatedDate column already exists'
    END

    -- Check CreatedBy_ID
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'CreatedBy_ID')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [CreatedBy_ID] [smallint] NULL
        PRINT '  Added CreatedBy_ID column'
    END
    ELSE
    BEGIN
        PRINT '  CreatedBy_ID column already exists'
    END

    -- Check IsActive
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'IsActive')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [IsActive] [bit] NOT NULL DEFAULT 1
        PRINT '  Added IsActive column'
    END
    ELSE
    BEGIN
        PRINT '  IsActive column already exists'
    END

    -- All other columns (TaxID, District, etc.) already exist in schema
    PRINT '  Other columns (TaxID, District, Subdistrict, Province, Postcode) already exist'

    PRINT ''

    -- ===================================================================
    -- Step 4: Add Foreign Key constraints
    -- ===================================================================

    PRINT 'Step 4: Adding foreign key constraints...'

    -- FK from Customer_Audit_Log to Customer
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customer_Audit_Log_Customer')
    BEGIN
        ALTER TABLE [dbo].[Customer_Audit_Log]
        ADD CONSTRAINT [FK_Customer_Audit_Log_Customer]
        FOREIGN KEY([Customer_ID])
        REFERENCES [dbo].[Customer] ([ID])
        ON UPDATE CASCADE
        ON DELETE CASCADE

        PRINT '  Added FK_Customer_Audit_Log_Customer'
    END
    ELSE
    BEGIN
        PRINT '  FK_Customer_Audit_Log_Customer already exists'
    END

    -- FK from Customer_Audit_Log to Admin
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customer_Audit_Log_Admin')
    BEGIN
        ALTER TABLE [dbo].[Customer_Audit_Log]
        ADD CONSTRAINT [FK_Customer_Audit_Log_Admin]
        FOREIGN KEY([ChangedBy_ID])
        REFERENCES [dbo].[Admin] ([ID])
        ON UPDATE NO ACTION
        ON DELETE SET NULL

        PRINT '  Added FK_Customer_Audit_Log_Admin'
    END
    ELSE
    BEGIN
        PRINT '  FK_Customer_Audit_Log_Admin already exists'
    END

    -- FK from Customer.LastUpdatedBy_ID to Admin
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customer_Admin_LastUpdated')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD CONSTRAINT [FK_Customer_Admin_LastUpdated]
        FOREIGN KEY([LastUpdatedBy_ID])
        REFERENCES [dbo].[Admin] ([ID])
        ON UPDATE NO ACTION
        ON DELETE SET NULL

        PRINT '  Added FK_Customer_Admin_LastUpdated'
    END
    ELSE
    BEGIN
        PRINT '  FK_Customer_Admin_LastUpdated already exists'
    END

    -- FK from Customer.CreatedBy_ID to Admin
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customer_Admin_Created')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD CONSTRAINT [FK_Customer_Admin_Created]
        FOREIGN KEY([CreatedBy_ID])
        REFERENCES [dbo].[Admin] ([ID])
        ON UPDATE NO ACTION
        ON DELETE SET NULL

        PRINT '  Added FK_Customer_Admin_Created'
    END
    ELSE
    BEGIN
        PRINT '  FK_Customer_Admin_Created already exists'
    END

    PRINT ''

    -- ===================================================================
    -- Step 5: Add indexes for performance
    -- ===================================================================

    PRINT 'Step 5: Creating performance indexes...'

    -- Index on Customer_Audit_Log
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_Audit_Log_Customer')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Customer_Audit_Log_Customer]
        ON [dbo].[Customer_Audit_Log] ([Customer_ID], [ChangeDate] DESC)

        PRINT '  Created IX_Customer_Audit_Log_Customer'
    END
    ELSE
    BEGIN
        PRINT '  IX_Customer_Audit_Log_Customer already exists'
    END

    -- Index on Customer.MobilePhone
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_MobilePhone')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Customer_MobilePhone]
        ON [dbo].[Customer] ([MobilePhone] ASC)
        WHERE [MobilePhone] IS NOT NULL

        PRINT '  Created IX_Customer_MobilePhone'
    END
    ELSE
    BEGIN
        PRINT '  IX_Customer_MobilePhone already exists'
    END

    -- Index on Customer.Email
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_Email')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Customer_Email]
        ON [dbo].[Customer] ([Email] ASC)
        WHERE [Email] IS NOT NULL

        PRINT '  Created IX_Customer_Email'
    END
    ELSE
    BEGIN
        PRINT '  IX_Customer_Email already exists'
    END

    -- Index on Customer.TaxID
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_TaxID')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Customer_TaxID]
        ON [dbo].[Customer] ([TaxID] ASC)
        WHERE [TaxID] IS NOT NULL

        PRINT '  Created IX_Customer_TaxID'
    END
    ELSE
    BEGIN
        PRINT '  IX_Customer_TaxID already exists'
    END

    -- Index on Customer.IsActive
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_IsActive')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Customer_IsActive]
        ON [dbo].[Customer] ([IsActive])
        INCLUDE ([ID], [Name], [MobilePhone])

        PRINT '  Created IX_Customer_IsActive'
    END
    ELSE
    BEGIN
        PRINT '  IX_Customer_IsActive already exists'
    END

    PRINT ''

    -- ===================================================================
    -- Step 6: Create stored procedure for customer upsert
    -- ===================================================================

    PRINT 'Step 6: Creating stored procedures...'

    -- Drop if exists
    IF OBJECT_ID('dbo.sp_UpsertCustomer', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_UpsertCustomer

    -- Create procedure
    EXEC('
    CREATE PROCEDURE [dbo].[sp_UpsertCustomer]
        @ID BIGINT = NULL OUTPUT,
        @MobilePhone NVARCHAR(30),
        @Name NVARCHAR(100),
        @NickName NVARCHAR(50) = NULL,
        @ComeFrom NVARCHAR(50) = NULL,
        @Email NVARCHAR(100) = NULL,
        @Address NVARCHAR(1000) = NULL,
        @IDNumber NVARCHAR(13) = NULL,
        @Customer_Type_ID SMALLINT = NULL,
        @TaxID NVARCHAR(20) = NULL,
        @ChangedBy_ID SMALLINT = NULL,
        @ChangedBy_Source NVARCHAR(100) = NULL,
        @IPAddress NVARCHAR(50) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ExistingID BIGINT
        DECLARE @Action NVARCHAR(20)

        -- Check if customer exists by ID or MobilePhone
        IF @ID IS NOT NULL
        BEGIN
            SELECT @ExistingID = ID FROM Customer WHERE ID = @ID
        END
        ELSE
        BEGIN
            SELECT @ExistingID = ID FROM Customer WHERE MobilePhone = @MobilePhone
        END

        IF @ExistingID IS NULL
        BEGIN
            -- INSERT new customer
            SET @Action = ''INSERT''

            INSERT INTO Customer (
                MobilePhone, Name, NickName, ComeFrom, Email,
                Address, IDNumber, Customer_Type_ID, TaxID,
                Status, IsActive, CreatedDate, CreatedBy_ID,
                LastUpdated, LastUpdatedBy_ID
            )
            VALUES (
                @MobilePhone, @Name, @NickName, @ComeFrom, @Email,
                @Address, @IDNumber, @Customer_Type_ID, @TaxID,
                1, 1, GETDATE(), @ChangedBy_ID,
                GETDATE(), @ChangedBy_ID
            )

            SET @ID = SCOPE_IDENTITY()

            -- Log audit
            INSERT INTO Customer_Audit_Log (
                Customer_ID, Action, ChangeDate, ChangedBy_ID,
                ChangedBy_Source, IPAddress, Notes
            )
            VALUES (
                @ID, @Action, GETDATE(), @ChangedBy_ID,
                @ChangedBy_Source, @IPAddress, ''New customer created''
            )
        END
        ELSE
        BEGIN
            -- UPDATE existing customer
            SET @Action = ''UPDATE''
            SET @ID = @ExistingID

            UPDATE Customer
            SET
                Name = @Name,
                NickName = @NickName,
                ComeFrom = @ComeFrom,
                Email = @Email,
                Address = @Address,
                IDNumber = @IDNumber,
                Customer_Type_ID = @Customer_Type_ID,
                TaxID = @TaxID,
                LastUpdated = GETDATE(),
                LastUpdatedBy_ID = @ChangedBy_ID
            WHERE ID = @ID

            -- Log audit
            INSERT INTO Customer_Audit_Log (
                Customer_ID, Action, ChangeDate, ChangedBy_ID,
                ChangedBy_Source, IPAddress, Notes
            )
            VALUES (
                @ID, @Action, GETDATE(), @ChangedBy_ID,
                @ChangedBy_Source, @IPAddress, ''Customer updated''
            )
        END

        SELECT @ID AS CustomerID, @Action AS Action
    END
    ')

    PRINT '  Created sp_UpsertCustomer'

    PRINT ''

    -- ===================================================================
    -- Step 7: Update existing customer records
    -- ===================================================================

    PRINT 'Step 7: Updating existing customer records...'

    -- Set CreatedDate for existing customers (if NULL)
    UPDATE Customer
    SET CreatedDate = GETDATE()
    WHERE CreatedDate IS NULL

    -- Set LastUpdated for existing customers (if NULL)
    UPDATE Customer
    SET LastUpdated = GETDATE()
    WHERE LastUpdated IS NULL

    PRINT '  Updated existing customer records'

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

    -- Rollback on error
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

    -- Record migration failure
    EXEC sp_RecordMigration
        @MigrationName = @MigrationName,
        @AppliedBy = SYSTEM_USER,
        @Success = 0,
        @ErrorMessage = @ErrorMessage

    -- Re-throw error
    THROW

END CATCH

MigrationEnd:

PRINT ''
PRINT '============================================================='
PRINT 'Migration script completed'
PRINT '============================================================='
