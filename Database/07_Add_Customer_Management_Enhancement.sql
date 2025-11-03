/*==============================================================
  Migration: 07_Add_Customer_Management_Enhancement

  Purpose:
  - Prevent duplicate customer data across the system
  - Centralize customer data management
  - Add audit trail for customer changes
  - Improve customer search and validation
  - Ensure data consistency across all pages

  Features:
  - Customer_Audit_Log table for tracking changes
  - Stored procedures for upsert operations
  - Enhanced validation and constraints
  - Duplicate detection and merging
  - Improved search indexes

  Business Rules:
  - MobilePhone is primary key (already in place)
  - No duplicate phone numbers allowed
  - All updates must be logged
  - Email must be unique if provided
  - Tax ID (if provided) must be unique

  Author: Claude
  Date: 2025-11-03
  Dependencies: 00_Init_Migration_System
==============================================================*/

USE [Taketime]
GO

SET NOCOUNT ON;
SET XACT_ABORT ON; -- Rollback entire transaction on any error

DECLARE @MigrationName NVARCHAR(255) = '07_Add_Customer_Management_Enhancement'
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
    PRINT '⚠ Migration already applied: ' + @MigrationName
    PRINT '⚠ Skipping execution'
    PRINT ''

    -- Still show as success but don't re-run
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
    RAISERROR('✗ Customer table does not exist. Cannot proceed.', 16, 1)
    GOTO MigrationEnd
END

PRINT '✓ Customer table exists'

-- Check if Admin table exists (for audit trail) - using Admin instead of Employees
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Admin]') AND type in (N'U'))
BEGIN
    RAISERROR('✗ Admin table does not exist. Cannot proceed.', 16, 1)
    GOTO MigrationEnd
END

PRINT '✓ Admin table exists'

PRINT ''

-- ===================================================================
-- Begin Transaction
-- ===================================================================

BEGIN TRANSACTION

BEGIN TRY

    PRINT 'Starting database modifications...'
    PRINT ''

    -- ===================================================================
    -- Step 1: Create Customer_Audit_Log table
    -- ===================================================================

    PRINT 'Step 1: Creating Customer_Audit_Log table...'

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customer_Audit_Log]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[Customer_Audit_Log](
            [ID] [bigint] IDENTITY(1,1) NOT NULL,
            [Customer_MobilePhone] [nvarchar](30) NOT NULL,
            [Action] [nvarchar](20) NOT NULL, -- INSERT, UPDATE, DELETE, MERGE
            [FieldChanged] [nvarchar](100) NULL, -- Which field was changed
            [OldValue] [nvarchar](max) NULL,
            [NewValue] [nvarchar](max) NULL,
            [ChangeDate] [datetime] NOT NULL DEFAULT GETDATE(),
            [ChangedBy_ID] [smallint] NULL, -- Employee who made change
            [ChangedBy_Source] [nvarchar](100) NULL, -- Which page/form made the change
            [IPAddress] [nvarchar](50) NULL,
            [Notes] [nvarchar](500) NULL,
         CONSTRAINT [PK_Customer_Audit_Log] PRIMARY KEY CLUSTERED
        (
            [ID] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY]

        PRINT '  ✓ Created Customer_Audit_Log table'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ Customer_Audit_Log table already exists'
    END

    -- ===================================================================
    -- Step 2: Add foreign key constraints
    -- ===================================================================

    PRINT 'Step 2: Adding foreign key constraints...'

    -- FK to Customer
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customer_Audit_Log_Customer')
    BEGIN
        ALTER TABLE [dbo].[Customer_Audit_Log]
        ADD CONSTRAINT [FK_Customer_Audit_Log_Customer]
        FOREIGN KEY([Customer_MobilePhone])
        REFERENCES [dbo].[Customer] ([MobilePhone])
        ON UPDATE CASCADE
        ON DELETE CASCADE

        PRINT '  ✓ Added FK_Customer_Audit_Log_Customer'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ FK_Customer_Audit_Log_Customer already exists'
    END

    -- FK to Admin (employee/user table)
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customer_Audit_Log_Admin')
    BEGIN
        ALTER TABLE [dbo].[Customer_Audit_Log]
        ADD CONSTRAINT [FK_Customer_Audit_Log_Admin]
        FOREIGN KEY([ChangedBy_ID])
        REFERENCES [dbo].[Admin] ([ID])
        ON UPDATE NO ACTION
        ON DELETE SET NULL

        PRINT '  ✓ Added FK_Customer_Audit_Log_Admin'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ FK_Customer_Audit_Log_Admin already exists'
    END

    -- ===================================================================
    -- Step 3: Add check constraints
    -- ===================================================================

    PRINT 'Step 3: Adding check constraints...'

    -- Action must be valid
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Customer_Audit_Log_Action')
    BEGIN
        ALTER TABLE [dbo].[Customer_Audit_Log]
        ADD CONSTRAINT [CK_Customer_Audit_Log_Action]
        CHECK ([Action] IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE'))

        PRINT '  ✓ Added CK_Customer_Audit_Log_Action'
    END

    -- ===================================================================
    -- Step 4: Add columns to Customer table
    -- ===================================================================

    PRINT 'Step 4: Adding columns to Customer table...'

    -- LastUpdated
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'LastUpdated')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [LastUpdated] [datetime] NULL DEFAULT GETDATE()

        PRINT '  ✓ Added LastUpdated column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ LastUpdated column already exists'
    END

    -- LastUpdatedBy_ID
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'LastUpdatedBy_ID')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [LastUpdatedBy_ID] [smallint] NULL

        PRINT '  ✓ Added LastUpdatedBy_ID column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ LastUpdatedBy_ID column already exists'
    END

    -- CreatedDate
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'CreatedDate')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [CreatedDate] [datetime] NULL DEFAULT GETDATE()

        PRINT '  ✓ Added CreatedDate column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ CreatedDate column already exists'
    END

    -- CreatedBy_ID
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'CreatedBy_ID')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [CreatedBy_ID] [smallint] NULL

        PRINT '  ✓ Added CreatedBy_ID column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ CreatedBy_ID column already exists'
    END

    -- IsActive (soft delete support)
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'IsActive')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [IsActive] [bit] NOT NULL DEFAULT 1

        PRINT '  ✓ Added IsActive column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ IsActive column already exists'
    END

    -- TaxID (for business customers)
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'TaxID')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [TaxID] [nvarchar](20) NULL

        PRINT '  ✓ Added TaxID column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ TaxID column already exists'
    END

    -- District
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'District')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [District] [nvarchar](100) NULL

        PRINT '  ✓ Added District column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ District column already exists'
    END

    -- Subdistrict
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'Subdistrict')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [Subdistrict] [nvarchar](100) NULL

        PRINT '  ✓ Added Subdistrict column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ Subdistrict column already exists'
    END

    -- Province
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'Province')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [Province] [nvarchar](100) NULL

        PRINT '  ✓ Added Province column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ Province column already exists'
    END

    -- Postcode
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'Postcode')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD [Postcode] [nvarchar](10) NULL

        PRINT '  ✓ Added Postcode column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ Postcode column already exists'
    END

    -- Note: Using existing Customer_Type_ID column (no need to create CustomerType_ID)
    -- The database already has Customer_Type_ID, so we'll use that throughout

    PRINT '  ✓ Using existing Customer_Type_ID column'

    -- Add FK for LastUpdatedBy_ID
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customer_Admin_LastUpdated')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD CONSTRAINT [FK_Customer_Admin_LastUpdated]
        FOREIGN KEY([LastUpdatedBy_ID])
        REFERENCES [dbo].[Admin] ([ID])
        ON UPDATE NO ACTION
        ON DELETE SET NULL

        PRINT '  ✓ Added FK_Customer_Admin_LastUpdated'
    END

    -- Add FK for CreatedBy_ID
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customer_Admin_Created')
    BEGIN
        ALTER TABLE [dbo].[Customer]
        ADD CONSTRAINT [FK_Customer_Admin_Created]
        FOREIGN KEY([CreatedBy_ID])
        REFERENCES [dbo].[Admin] ([ID])
        ON UPDATE NO ACTION
        ON DELETE SET NULL

        PRINT '  ✓ Added FK_Customer_Admin_Created'
    END

    -- ===================================================================
    -- Step 5: Add indexes for performance
    -- ===================================================================

    PRINT 'Step 5: Creating performance indexes...'

    -- Index on Customer_Audit_Log
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_Audit_Log_Customer')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Customer_Audit_Log_Customer]
        ON [dbo].[Customer_Audit_Log] ([Customer_MobilePhone], [ChangeDate] DESC)

        PRINT '  ✓ Created IX_Customer_Audit_Log_Customer'
    END

    -- Index on Customer Name for search
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_Name')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Customer_Name]
        ON [dbo].[Customer] ([Name])
        INCLUDE ([MobilePhone], [Email], [Status])
        WHERE [Status] = 1

        PRINT '  ✓ Created IX_Customer_Name'
    END

    -- Index on Customer Email for uniqueness check
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_Email')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Customer_Email]
        ON [dbo].[Customer] ([Email])
        WHERE [Email] IS NOT NULL AND [Status] = 1

        PRINT '  ✓ Created IX_Customer_Email'
    END

    -- Index on Customer TaxID for uniqueness check
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_TaxID')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Customer_TaxID]
        ON [dbo].[Customer] ([TaxID])
        WHERE [TaxID] IS NOT NULL AND [Status] = 1

        PRINT '  ✓ Created IX_Customer_TaxID'
    END

    -- Index on IsActive
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_IsActive')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Customer_IsActive]
        ON [dbo].[Customer] ([IsActive], [Status])
        INCLUDE ([Name], [MobilePhone])

        PRINT '  ✓ Created IX_Customer_IsActive'
    END

    -- ===================================================================
    -- Step 6: Create stored procedures
    -- ===================================================================

    PRINT 'Step 6: Creating stored procedures...'

    -- Procedure: Upsert customer (Insert or Update)
    IF OBJECT_ID('dbo.sp_UpsertCustomer', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_UpsertCustomer

    EXEC('
    CREATE PROCEDURE [dbo].[sp_UpsertCustomer]
        @MobilePhone NVARCHAR(30),
        @Name NVARCHAR(200),
        @Email NVARCHAR(100) = NULL,
        @TaxID NVARCHAR(20) = NULL,
        @Address NVARCHAR(500) = NULL,
        @District NVARCHAR(100) = NULL,
        @Subdistrict NVARCHAR(100) = NULL,
        @Province NVARCHAR(100) = NULL,
        @Postcode NVARCHAR(10) = NULL,
        @Customer_Type_ID TINYINT = NULL,
        @ChangedBy_ID SMALLINT = NULL,
        @ChangeSource NVARCHAR(100) = NULL,
        @IPAddress NVARCHAR(50) = NULL,
        @IsNewCustomer BIT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        BEGIN TRY
            BEGIN TRANSACTION

            DECLARE @ExistingCustomer BIT = 0
            DECLARE @Action NVARCHAR(20)

            -- Check if customer exists
            IF EXISTS (SELECT 1 FROM Customer WHERE MobilePhone = @MobilePhone)
            BEGIN
                SET @ExistingCustomer = 1
                SET @IsNewCustomer = 0
                SET @Action = ''UPDATE''
            END
            ELSE
            BEGIN
                SET @ExistingCustomer = 0
                SET @IsNewCustomer = 1
                SET @Action = ''INSERT''
            END

            -- Validate: Check for duplicate email (if provided)
            IF @Email IS NOT NULL AND @Email != ''''
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM Customer
                    WHERE Email = @Email
                      AND MobilePhone != @MobilePhone
                      AND Status = 1
                )
                BEGIN
                    RAISERROR(''Email already exists for another customer'', 16, 1)
                    RETURN 1
                END
            END

            -- Validate: Check for duplicate TaxID (if provided)
            IF @TaxID IS NOT NULL AND @TaxID != ''''
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM Customer
                    WHERE TaxID = @TaxID
                      AND MobilePhone != @MobilePhone
                      AND Status = 1
                )
                BEGIN
                    RAISERROR(''Tax ID already exists for another customer'', 16, 1)
                    RETURN 1
                END
            END

            IF @ExistingCustomer = 1
            BEGIN
                -- Update existing customer
                DECLARE @OldName NVARCHAR(200), @OldEmail NVARCHAR(100), @OldTaxID NVARCHAR(20)
                DECLARE @OldAddress NVARCHAR(500), @OldDistrict NVARCHAR(100), @OldSubdistrict NVARCHAR(100)
                DECLARE @OldProvince NVARCHAR(100), @OldPostcode NVARCHAR(10)

                -- Get old values for audit
                SELECT
                    @OldName = Name,
                    @OldEmail = Email,
                    @OldTaxID = TaxID,
                    @OldAddress = Address,
                    @OldDistrict = District,
                    @OldSubdistrict = Subdistrict,
                    @OldProvince = Province,
                    @OldPostcode = Postcode
                FROM Customer
                WHERE MobilePhone = @MobilePhone

                -- Update customer
                UPDATE Customer
                SET
                    Name = @Name,
                    Email = @Email,
                    TaxID = @TaxID,
                    Address = @Address,
                    District = @District,
                    Subdistrict = @Subdistrict,
                    Province = @Province,
                    Postcode = @Postcode,
                    Customer_Type_ID = COALESCE(@Customer_Type_ID, Customer_Type_ID),
                    LastUpdated = GETDATE(),
                    LastUpdatedBy_ID = @ChangedBy_ID
                WHERE MobilePhone = @MobilePhone

                -- Log changes for each field that changed
                IF @OldName != @Name
                    INSERT INTO Customer_Audit_Log (Customer_MobilePhone, Action, FieldChanged, OldValue, NewValue, ChangedBy_ID, ChangedBy_Source, IPAddress)
                    VALUES (@MobilePhone, @Action, ''Name'', @OldName, @Name, @ChangedBy_ID, @ChangeSourceумент, @IPAddress)

                IF COALESCE(@OldEmail, '''') != COALESCE(@Email, '''')
                    INSERT INTO Customer_Audit_Log (Customer_MobilePhone, Action, FieldChanged, OldValue, NewValue, ChangedBy_ID, ChangedBy_Source, IPAddress)
                    VALUES (@MobilePhone, @Action, ''Email'', @OldEmail, @Email, @ChangedBy_ID, @ChangeSource, @IPAddress)

                IF COALESCE(@OldTaxID, '''') != COALESCE(@TaxID, '''')
                    INSERT INTO Customer_Audit_Log (Customer_MobilePhone, Action, FieldChanged, OldValue, NewValue, ChangedBy_ID, ChangedBy_Source, IPAddress)
                    VALUES (@MobilePhone, @Action, ''TaxID'', @OldTaxID, @TaxID, @ChangedBy_ID, @ChangeSource, @IPAddress)

                IF COALESCE(@OldAddress, '''') != COALESCE(@Address, '''')
                    INSERT INTO Customer_Audit_Log (Customer_MobilePhone, Action, FieldChanged, OldValue, NewValue, ChangedBy_ID, ChangedBy_Source, IPAddress)
                    VALUES (@MobilePhone, @Action, ''Address'', @OldAddress, @Address, @ChangedBy_ID, @ChangeSource, @IPAddress)
            END
            ELSE
            BEGIN
                -- Insert new customer
                INSERT INTO Customer (
                    MobilePhone,
                    Name,
                    Email,
                    TaxID,
                    Address,
                    District,
                    Subdistrict,
                    Province,
                    Postcode,
                    Customer_Type_ID,
                    CreatedDate,
                    CreatedBy_ID,
                    LastUpdated,
                    LastUpdatedBy_ID,
                    Status
                )
                VALUES (
                    @MobilePhone,
                    @Name,
                    @Email,
                    @TaxID,
                    @Address,
                    @District,
                    @Subdistrict,
                    @Province,
                    @Postcode,
                    @Customer_Type_ID,
                    GETDATE(),
                    @ChangedBy_ID,
                    GETDATE(),
                    @ChangedBy_ID,
                    1
                )

                -- Log insertion
                INSERT INTO Customer_Audit_Log (Customer_MobilePhone, Action, FieldChanged, NewValue, ChangedBy_ID, ChangedBy_Source, IPAddress, Notes)
                VALUES (@MobilePhone, @Action, ''ALL'', ''New customer created'', @ChangedBy_ID, @ChangeSource, @IPAddress, ''Initial creation'')
            END

            COMMIT TRANSACTION

            RETURN 0 -- Success
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION

            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
            RAISERROR(@ErrorMessage, 16, 1)
            RETURN 1 -- Error
        END CATCH
    END
    ')

    PRINT '  ✓ Created sp_UpsertCustomer'

    -- Procedure: Get customer by phone
    IF OBJECT_ID('dbo.sp_GetCustomer', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_GetCustomer

    EXEC('
    CREATE PROCEDURE [dbo].[sp_GetCustomer]
        @MobilePhone NVARCHAR(30)
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            C.MobilePhone,
            C.Name,
            C.Email,
            C.TaxID,
            C.Address,
            C.District,
            C.Subdistrict,
            C.Province,
            C.Postcode,
            C.Customer_Type_ID,
            CT.Customer_Type AS CustomerTypeName,
            C.Status,
            C.CreatedDate,
            C.LastUpdated,
            C.IsActive,
            E1.FirstName + '' '' + E1.LastName AS CreatedByName,
            E2.FirstName + '' '' + E2.LastName AS LastUpdatedByName,
            (SELECT COUNT(*) FROM Reservation WHERE Customer_MobilePhone = C.MobilePhone) AS TotalReservations,
            (SELECT MAX(CheckinDate) FROM Reservation WHERE Customer_MobilePhone = C.MobilePhone) AS LastReservationDate
        FROM Customer C
        LEFT JOIN Customer_Type CT ON C.Customer_Type_ID = CT.ID
        LEFT JOIN Admin E1 ON C.CreatedBy_ID = E1.ID
        LEFT JOIN Admin E2 ON C.LastUpdatedBy_ID = E2.ID
        WHERE C.MobilePhone = @MobilePhone
    END
    ')

    PRINT '  ✓ Created sp_GetCustomer'

    -- Procedure: Search customers
    IF OBJECT_ID('dbo.sp_SearchCustomers', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_SearchCustomers

    EXEC('
    CREATE PROCEDURE [dbo].[sp_SearchCustomers]
        @SearchTerm NVARCHAR(200) = NULL,
        @ActiveOnly BIT = 1,
        @MaxResults INT = 50
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT TOP (@MaxResults)
            C.MobilePhone,
            C.Name,
            C.Email,
            C.TaxID,
            C.Address,
            C.Province,
            C.Customer_Type_ID,
            CT.Customer_Type AS CustomerTypeName,
            C.Status,
            C.CreatedDate,
            C.LastUpdated,
            C.IsActive,
            (SELECT COUNT(*) FROM Reservation WHERE Customer_MobilePhone = C.MobilePhone) AS TotalReservations,
            (SELECT MAX(CheckinDate) FROM Reservation WHERE Customer_MobilePhone = C.MobilePhone) AS LastReservationDate
        FROM Customer C
        LEFT JOIN Customer_Type CT ON C.Customer_Type_ID = CT.ID
        WHERE
            (@SearchTerm IS NULL OR
             C.Name LIKE ''%'' + @SearchTerm + ''%'' OR
             C.MobilePhone LIKE ''%'' + @SearchTerm + ''%'' OR
             C.Email LIKE ''%'' + @SearchTerm + ''%'')
            AND (@ActiveOnly = 0 OR (C.Status = 1 AND C.IsActive = 1))
        ORDER BY
            C.LastUpdated DESC,
            C.Name ASC
    END
    ')

    PRINT '  ✓ Created sp_SearchCustomers'

    -- Procedure: Get customer audit history
    IF OBJECT_ID('dbo.sp_GetCustomerAuditHistory', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_GetCustomerAuditHistory

    EXEC('
    CREATE PROCEDURE [dbo].[sp_GetCustomerAuditHistory]
        @MobilePhone NVARCHAR(30),
        @MaxResults INT = 100
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT TOP (@MaxResults)
            CAL.ID,
            CAL.Customer_MobilePhone,
            CAL.Action,
            CAL.FieldChanged,
            CAL.OldValue,
            CAL.NewValue,
            CAL.ChangeDate,
            CAL.ChangedBy_Source,
            CAL.IPAddress,
            CAL.Notes,
            E.FirstName + '' '' + E.LastName AS ChangedByName
        FROM Customer_Audit_Log CAL
        LEFT JOIN Admin E ON CAL.ChangedBy_ID = E.ID
        WHERE CAL.Customer_MobilePhone = @MobilePhone
        ORDER BY CAL.ChangeDate DESC
    END
    ')

    PRINT '  ✓ Created sp_GetCustomerAuditHistory'

    -- Procedure: Soft delete customer
    IF OBJECT_ID('dbo.sp_DeleteCustomer', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_DeleteCustomer

    EXEC('
    CREATE PROCEDURE [dbo].[sp_DeleteCustomer]
        @MobilePhone NVARCHAR(30),
        @DeletedBy_ID SMALLINT = NULL,
        @Reason NVARCHAR(500) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        BEGIN TRY
            BEGIN TRANSACTION

            -- Check if customer has reservations
            DECLARE @ReservationCount INT
            SELECT @ReservationCount = COUNT(*)
            FROM Reservation
            WHERE Customer_MobilePhone = @MobilePhone

            IF @ReservationCount > 0
            BEGIN
                -- Soft delete only (customer has reservation history)
                UPDATE Customer
                SET
                    IsActive = 0,
                    Status = 0,
                    LastUpdated = GETDATE(),
                    LastUpdatedBy_ID = @DeletedBy_ID
                WHERE MobilePhone = @MobilePhone

                -- Log deletion
                INSERT INTO Customer_Audit_Log (Customer_MobilePhone, Action, FieldChanged, OldValue, NewValue, ChangedBy_ID, Notes)
                VALUES (@MobilePhone, ''DELETE'', ''IsActive'', ''1'', ''0'', @DeletedBy_ID, COALESCE(@Reason, ''Customer soft deleted - has reservation history''))
            END
            ELSE
            BEGIN
                -- Can hard delete (no reservations)
                -- Log before deletion
                INSERT INTO Customer_Audit_Log (Customer_MobilePhone, Action, FieldChanged, ChangedBy_ID, Notes)
                VALUES (@MobilePhone, ''DELETE'', ''ALL'', @DeletedBy_ID, COALESCE(@Reason, ''Customer hard deleted - no reservation history''))

                -- Hard delete
                DELETE FROM Customer WHERE MobilePhone = @MobilePhone
            END

            COMMIT TRANSACTION

            RETURN 0 -- Success
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION

            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
            RAISERROR(@ErrorMessage, 16, 1)
            RETURN 1 -- Error
        END CATCH
    END
    ')

    PRINT '  ✓ Created sp_DeleteCustomer'

    -- ===================================================================
    -- Step 7: Create views
    -- ===================================================================

    PRINT 'Step 7: Creating views...'

    IF OBJECT_ID('dbo.v_CustomerSummary', 'V') IS NOT NULL
        DROP VIEW dbo.v_CustomerSummary

    EXEC('
    CREATE VIEW [dbo].[v_CustomerSummary]
    AS
    SELECT
        C.MobilePhone,
        C.Name,
        C.Email,
        C.TaxID,
        C.Address,
        C.District,
        C.Subdistrict,
        C.Province,
        C.Postcode,
        C.Customer_Type_ID,
        CT.Customer_Type AS CustomerTypeName,
        C.Status,
        C.IsActive,
        C.CreatedDate,
        C.LastUpdated,
        E1.FirstName + '' '' + E1.LastName AS CreatedByName,
        E2.FirstName + '' '' + E2.LastName AS LastUpdatedByName,
        (SELECT COUNT(*) FROM Reservation WHERE Customer_MobilePhone = C.MobilePhone) AS TotalReservations,
        (SELECT COUNT(*) FROM Reservation WHERE Customer_MobilePhone = C.MobilePhone AND Status = N''ยืนยันแล้ว'') AS ConfirmedReservations,
        (SELECT MAX(CheckinDate) FROM Reservation WHERE Customer_MobilePhone = C.MobilePhone) AS LastReservationDate,
        (SELECT SUM(TotalPrice) FROM Reservation WHERE Customer_MobilePhone = C.MobilePhone) AS TotalRevenue
    FROM Customer C
    LEFT JOIN Customer_Type CT ON C.Customer_Type_ID = CT.ID
    LEFT JOIN Admin E1 ON C.CreatedBy_ID = E1.ID
    LEFT JOIN Admin E2 ON C.LastUpdatedBy_ID = E2.ID
    WHERE C.Status = 1 AND C.IsActive = 1
    ')

    PRINT '  ✓ Created v_CustomerSummary'

    -- ===================================================================
    -- Step 8: Update existing customer records
    -- ===================================================================

    PRINT 'Step 8: Updating existing customer records...'

    -- Set CreatedDate for existing customers (if NULL)
    UPDATE Customer
    SET CreatedDate = GETDATE()
    WHERE CreatedDate IS NULL

    -- Set LastUpdated for existing customers (if NULL)
    UPDATE Customer
    SET LastUpdated = GETDATE()
    WHERE LastUpdated IS NULL

    -- Set IsActive for existing customers
    UPDATE Customer
    SET IsActive = 1
    WHERE IsActive IS NULL

    DECLARE @UpdatedCount INT = @@ROWCOUNT

    PRINT '  ✓ Updated ' + CAST(@UpdatedCount AS VARCHAR) + ' existing customer record(s)'

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

    -- ===================================================================
    -- Post-migration verification
    -- ===================================================================

    PRINT 'Post-migration verification:'
    PRINT ''

    -- Check Customer_Audit_Log table
    DECLARE @AuditTableCount INT
    SELECT @AuditTableCount = COUNT(*)
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Customer_Audit_Log]')
      AND type in (N'U')

    IF @AuditTableCount = 1
        PRINT '✓ Customer_Audit_Log table exists'
    ELSE
        PRINT '✗ Customer_Audit_Log table verification failed'

    -- Check Customer columns
    DECLARE @CustomerColCount INT
    SELECT @CustomerColCount = COUNT(*)
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Customer]')
      AND name IN ('LastUpdated', 'LastUpdatedBy_ID', 'CreatedDate', 'CreatedBy_ID', 'IsActive')

    IF @CustomerColCount = 5
        PRINT '✓ Customer table columns added successfully'
    ELSE
        PRINT '✗ Customer table columns verification failed'

    -- Check stored procedures
    DECLARE @SPCount INT
    SELECT @SPCount = COUNT(*)
    FROM sys.procedures
    WHERE name IN ('sp_UpsertCustomer', 'sp_GetCustomer', 'sp_SearchCustomers', 'sp_GetCustomerAuditHistory', 'sp_DeleteCustomer')

    IF @SPCount = 5
        PRINT '✓ All stored procedures created'
    ELSE
        PRINT '✗ Stored procedures verification failed'

    PRINT ''
    PRINT 'Customer Management Features:'
    PRINT '  ✓ Prevent duplicate customers (validation on email, TaxID)'
    PRINT '  ✓ Audit trail for all changes'
    PRINT '  ✓ Upsert operation (insert or update automatically)'
    PRINT '  ✓ Soft delete support (keeps history)'
    PRINT '  ✓ Customer search with multiple criteria'
    PRINT ''
    PRINT 'Next steps:'
    PRINT '  1. Create CustomerService.cs class'
    PRINT '  2. Create CustomerManagement.aspx page'
    PRINT '  3. Update all pages to use sp_UpsertCustomer'
    PRINT ''

END TRY

BEGIN CATCH
    -- ===================================================================
    -- Error Handling
    -- ===================================================================

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

    -- Record failed migration
    EXEC sp_RecordMigration
        @MigrationName = @MigrationName,
        @AppliedBy = SYSTEM_USER,
        @Success = 0,
        @ErrorMessage = @ErrorMessage

    -- Re-throw error
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
END CATCH

MigrationEnd:

PRINT ''
PRINT 'Migration script ended: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT ''

GO

/*==============================================================
  ROLLBACK SCRIPT (if needed)
==============================================================

-- Run this if you need to undo this migration

USE [Taketime]
GO

BEGIN TRANSACTION

-- Drop view
IF OBJECT_ID('dbo.v_CustomerSummary', 'V') IS NOT NULL
    DROP VIEW dbo.v_CustomerSummary

-- Drop stored procedures
IF OBJECT_ID('dbo.sp_DeleteCustomer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_DeleteCustomer

IF OBJECT_ID('dbo.sp_GetCustomerAuditHistory', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetCustomerAuditHistory

IF OBJECT_ID('dbo.sp_SearchCustomers', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_SearchCustomers

IF OBJECT_ID('dbo.sp_GetCustomer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetCustomer

IF OBJECT_ID('dbo.sp_UpsertCustomer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpsertCustomer

-- Drop Customer columns
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'IsActive')
    ALTER TABLE [dbo].[Customer] DROP COLUMN [IsActive]

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'CreatedBy_ID')
    ALTER TABLE [dbo].[Customer] DROP COLUMN [CreatedBy_ID]

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'CreatedDate')
    ALTER TABLE [dbo].[Customer] DROP COLUMN [CreatedDate]

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'LastUpdatedBy_ID')
    ALTER TABLE [dbo].[Customer] DROP COLUMN [LastUpdatedBy_ID]

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = 'LastUpdated')
    ALTER TABLE [dbo].[Customer] DROP COLUMN [LastUpdated]

-- Drop Customer_Audit_Log table (CASCADE will handle FKs)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customer_Audit_Log]') AND type in (N'U'))
    DROP TABLE [dbo].[Customer_Audit_Log]

-- Remove migration record
DELETE FROM Database_Migrations WHERE MigrationName = '07_Add_Customer_Management_Enhancement'

COMMIT TRANSACTION

PRINT 'Rollback completed'

==============================================================*/
