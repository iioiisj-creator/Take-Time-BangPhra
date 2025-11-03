/*==============================================================
  Migration: 06_Add_Room_Status_System

  Purpose:
  - Track real-time room/accommodation status
  - Support housekeeping operations
  - Enable proper PMS room management
  - Track room occupancy and cleanliness

  Features:
  - Room_Status table for current status tracking
  - Housekeeping status management
  - Occupancy tracking
  - Maintenance tracking
  - Status history logging

  Room Status Types:
  - VACANT_CLEAN: Ready for new guest
  - VACANT_DIRTY: Needs cleaning
  - OCCUPIED_CLEAN: Guest checked in, room clean
  - OCCUPIED_DIRTY: Guest checked in, needs cleaning
  - OUT_OF_ORDER: Under maintenance
  - RESERVED: Reserved but not checked in

  Author: Claude
  Date: 2025-11-03
  Dependencies: 00_Init_Migration_System, 03_Add_PMS_Guest_Folio_System
==============================================================*/

USE [Taketime]
GO

SET NOCOUNT ON;
SET XACT_ABORT ON; -- Rollback entire transaction on any error

DECLARE @MigrationName NVARCHAR(255) = '06_Add_Room_Status_System'
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

-- Check if Accommodation table exists
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Accommodation]') AND type in (N'U'))
BEGIN
    RAISERROR('✗ Accommodation table does not exist. Cannot proceed.', 16, 1)
    GOTO MigrationEnd
END

PRINT '✓ Accommodation table exists'

-- Check if Reservation table exists
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Reservation]') AND type in (N'U'))
BEGIN
    RAISERROR('✗ Reservation table does not exist. Cannot proceed.', 16, 1)
    GOTO MigrationEnd
END

PRINT '✓ Reservation table exists'

PRINT ''

-- ===================================================================
-- Begin Transaction
-- ===================================================================

BEGIN TRANSACTION

BEGIN TRY

    PRINT 'Starting database modifications...'
    PRINT ''

    -- ===================================================================
    -- Step 1: Create Room_Status table
    -- ===================================================================

    PRINT 'Step 1: Creating Room_Status table...'

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Room_Status]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[Room_Status](
            [ID] [bigint] IDENTITY(1,1) NOT NULL,
            [Accommodation_ID] [int] NOT NULL,
            [CurrentStatus] [nvarchar](30) NOT NULL DEFAULT 'VACANT_CLEAN',
            [HousekeepingStatus] [nvarchar](30) NOT NULL DEFAULT 'CLEAN',
            [OccupancyStatus] [nvarchar](30) NOT NULL DEFAULT 'VACANT',
            [IsOccupied] [bit] NOT NULL DEFAULT 0,
            [CurrentReservation_ID] [bigint] NULL,
            [CurrentGuest_Name] [nvarchar](200) NULL,
            [CheckedInDate] [datetime] NULL,
            [ExpectedCheckOutDate] [datetime] NULL,
            [LastCleanedDate] [datetime] NULL,
            [LastCleanedBy_ID] [smallint] NULL,
            [MaintenanceRequired] [bit] NOT NULL DEFAULT 0,
            [MaintenanceNotes] [nvarchar](1000) NULL,
            [MaintenanceStartDate] [datetime] NULL,
            [MaintenanceEndDate] [datetime] NULL,
            [LastStatusChange] [datetime] NOT NULL DEFAULT GETDATE(),
            [LastStatusChangedBy_ID] [smallint] NULL,
            [Notes] [nvarchar](1000) NULL,
            [IsActive] [bit] NOT NULL DEFAULT 1,
            [Status] [tinyint] NOT NULL DEFAULT 1,
         CONSTRAINT [PK_Room_Status] PRIMARY KEY CLUSTERED
        (
            [ID] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
         CONSTRAINT [UQ_Room_Status_Accommodation] UNIQUE NONCLUSTERED
        (
            [Accommodation_ID] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY]

        PRINT '  ✓ Created Room_Status table'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ Room_Status table already exists'
    END

    -- ===================================================================
    -- Step 2: Create Room_Status_History table
    -- ===================================================================

    PRINT 'Step 2: Creating Room_Status_History table...'

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Room_Status_History]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[Room_Status_History](
            [ID] [bigint] IDENTITY(1,1) NOT NULL,
            [Room_Status_ID] [bigint] NOT NULL,
            [Accommodation_ID] [int] NOT NULL,
            [PreviousStatus] [nvarchar](30) NULL,
            [NewStatus] [nvarchar](30) NOT NULL,
            [ChangeDate] [datetime] NOT NULL DEFAULT GETDATE(),
            [ChangedBy_ID] [smallint] NULL,
            [ChangeReason] [nvarchar](500) NULL,
            [Reservation_ID] [bigint] NULL,
            [Notes] [nvarchar](1000) NULL,
         CONSTRAINT [PK_Room_Status_History] PRIMARY KEY CLUSTERED
        (
            [ID] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY]

        PRINT '  ✓ Created Room_Status_History table'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ Room_Status_History table already exists'
    END

    -- ===================================================================
    -- Step 3: Add foreign key constraints
    -- ===================================================================

    PRINT 'Step 3: Adding foreign key constraints...'

    -- FK: Room_Status to Accommodation
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Room_Status_Accommodation')
    BEGIN
        ALTER TABLE [dbo].[Room_Status]
        ADD CONSTRAINT [FK_Room_Status_Accommodation]
        FOREIGN KEY([Accommodation_ID])
        REFERENCES [dbo].[Accommodation] ([ID])
        ON UPDATE CASCADE
        ON DELETE CASCADE

        PRINT '  ✓ Added FK_Room_Status_Accommodation'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ FK_Room_Status_Accommodation already exists'
    END

    -- FK: Room_Status to Reservation
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Room_Status_Reservation')
    BEGIN
        ALTER TABLE [dbo].[Room_Status]
        ADD CONSTRAINT [FK_Room_Status_Reservation]
        FOREIGN KEY([CurrentReservation_ID])
        REFERENCES [dbo].[Reservation] ([ID])
        ON UPDATE NO ACTION
        ON DELETE SET NULL

        PRINT '  ✓ Added FK_Room_Status_Reservation'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ FK_Room_Status_Reservation already exists'
    END

    -- FK: Room_Status to Employees (LastCleanedBy)
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Room_Status_Employees_Cleaned')
    BEGIN
        ALTER TABLE [dbo].[Room_Status]
        ADD CONSTRAINT [FK_Room_Status_Employees_Cleaned]
        FOREIGN KEY([LastCleanedBy_ID])
        REFERENCES [dbo].[Employees] ([ID])
        ON UPDATE NO ACTION
        ON DELETE SET NULL

        PRINT '  ✓ Added FK_Room_Status_Employees_Cleaned'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ FK_Room_Status_Employees_Cleaned already exists'
    END

    -- FK: Room_Status to Employees (LastStatusChangedBy)
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Room_Status_Employees_StatusChange')
    BEGIN
        ALTER TABLE [dbo].[Room_Status]
        ADD CONSTRAINT [FK_Room_Status_Employees_StatusChange]
        FOREIGN KEY([LastStatusChangedBy_ID])
        REFERENCES [dbo].[Employees] ([ID])
        ON UPDATE NO ACTION
        ON DELETE SET NULL

        PRINT '  ✓ Added FK_Room_Status_Employees_StatusChange'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ FK_Room_Status_Employees_StatusChange already exists'
    END

    -- FK: Room_Status_History to Room_Status
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Room_Status_History_Room_Status')
    BEGIN
        ALTER TABLE [dbo].[Room_Status_History]
        ADD CONSTRAINT [FK_Room_Status_History_Room_Status]
        FOREIGN KEY([Room_Status_ID])
        REFERENCES [dbo].[Room_Status] ([ID])
        ON UPDATE CASCADE
        ON DELETE CASCADE

        PRINT '  ✓ Added FK_Room_Status_History_Room_Status'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ FK_Room_Status_History_Room_Status already exists'
    END

    -- FK: Room_Status_History to Accommodation
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Room_Status_History_Accommodation')
    BEGIN
        ALTER TABLE [dbo].[Room_Status_History]
        ADD CONSTRAINT [FK_Room_Status_History_Accommodation]
        FOREIGN KEY([Accommodation_ID])
        REFERENCES [dbo].[Accommodation] ([ID])
        ON UPDATE NO ACTION
        ON DELETE NO ACTION

        PRINT '  ✓ Added FK_Room_Status_History_Accommodation'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ FK_Room_Status_History_Accommodation already exists'
    END

    -- FK: Room_Status_History to Employees
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Room_Status_History_Employees')
    BEGIN
        ALTER TABLE [dbo].[Room_Status_History]
        ADD CONSTRAINT [FK_Room_Status_History_Employees]
        FOREIGN KEY([ChangedBy_ID])
        REFERENCES [dbo].[Employees] ([ID])
        ON UPDATE NO ACTION
        ON DELETE SET NULL

        PRINT '  ✓ Added FK_Room_Status_History_Employees'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ FK_Room_Status_History_Employees already exists'
    END

    -- ===================================================================
    -- Step 4: Add check constraints
    -- ===================================================================

    PRINT 'Step 4: Adding check constraints...'

    -- CurrentStatus must be valid
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Room_Status_CurrentStatus')
    BEGIN
        ALTER TABLE [dbo].[Room_Status]
        ADD CONSTRAINT [CK_Room_Status_CurrentStatus]
        CHECK ([CurrentStatus] IN (
            'VACANT_CLEAN',
            'VACANT_DIRTY',
            'OCCUPIED_CLEAN',
            'OCCUPIED_DIRTY',
            'OUT_OF_ORDER',
            'RESERVED'
        ))

        PRINT '  ✓ Added CK_Room_Status_CurrentStatus'
    END

    -- HousekeepingStatus must be valid
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Room_Status_HousekeepingStatus')
    BEGIN
        ALTER TABLE [dbo].[Room_Status]
        ADD CONSTRAINT [CK_Room_Status_HousekeepingStatus]
        CHECK ([HousekeepingStatus] IN (
            'CLEAN',
            'DIRTY',
            'IN_PROGRESS',
            'INSPECTED'
        ))

        PRINT '  ✓ Added CK_Room_Status_HousekeepingStatus'
    END

    -- OccupancyStatus must be valid
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Room_Status_OccupancyStatus')
    BEGIN
        ALTER TABLE [dbo].[Room_Status]
        ADD CONSTRAINT [CK_Room_Status_OccupancyStatus]
        CHECK ([OccupancyStatus] IN (
            'VACANT',
            'OCCUPIED',
            'RESERVED',
            'OUT_OF_ORDER'
        ))

        PRINT '  ✓ Added CK_Room_Status_OccupancyStatus'
    END

    -- Status must be 0 or 1
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Room_Status_Status')
    BEGIN
        ALTER TABLE [dbo].[Room_Status]
        ADD CONSTRAINT [CK_Room_Status_Status]
        CHECK ([Status] IN (0, 1))

        PRINT '  ✓ Added CK_Room_Status_Status'
    END

    -- ===================================================================
    -- Step 5: Add indexes for performance
    -- ===================================================================

    PRINT 'Step 5: Creating performance indexes...'

    -- Index on CurrentStatus for filtering
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Room_Status_CurrentStatus')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Room_Status_CurrentStatus]
        ON [dbo].[Room_Status] ([CurrentStatus], [IsActive])
        INCLUDE ([Accommodation_ID], [IsOccupied])

        PRINT '  ✓ Created IX_Room_Status_CurrentStatus'
    END

    -- Index on OccupancyStatus
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Room_Status_OccupancyStatus')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Room_Status_OccupancyStatus]
        ON [dbo].[Room_Status] ([OccupancyStatus], [IsActive])

        PRINT '  ✓ Created IX_Room_Status_OccupancyStatus'
    END

    -- Index on HousekeepingStatus
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Room_Status_HousekeepingStatus')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Room_Status_HousekeepingStatus]
        ON [dbo].[Room_Status] ([HousekeepingStatus], [IsActive])

        PRINT '  ✓ Created IX_Room_Status_HousekeepingStatus'
    END

    -- Index on CurrentReservation_ID
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Room_Status_CurrentReservation')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Room_Status_CurrentReservation]
        ON [dbo].[Room_Status] ([CurrentReservation_ID])
        WHERE [CurrentReservation_ID] IS NOT NULL

        PRINT '  ✓ Created IX_Room_Status_CurrentReservation'
    END

    -- Index on Room_Status_History for lookups
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Room_Status_History_Accommodation')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Room_Status_History_Accommodation]
        ON [dbo].[Room_Status_History] ([Accommodation_ID], [ChangeDate] DESC)

        PRINT '  ✓ Created IX_Room_Status_History_Accommodation'
    END

    -- ===================================================================
    -- Step 6: Initialize room status for existing accommodations
    -- ===================================================================

    PRINT 'Step 6: Initializing room status for existing accommodations...'

    INSERT INTO Room_Status (
        Accommodation_ID,
        CurrentStatus,
        HousekeepingStatus,
        OccupancyStatus,
        IsOccupied
    )
    SELECT
        A.ID,
        'VACANT_CLEAN', -- Default status
        'CLEAN',
        'VACANT',
        0
    FROM Accommodation A
    WHERE A.Status = 1
      AND NOT EXISTS (
          SELECT 1
          FROM Room_Status RS
          WHERE RS.Accommodation_ID = A.ID
      )

    DECLARE @InitializedCount INT = @@ROWCOUNT

    PRINT '  ✓ Initialized status for ' + CAST(@InitializedCount AS VARCHAR) + ' room(s)'

    -- ===================================================================
    -- Step 7: Create stored procedures
    -- ===================================================================

    PRINT 'Step 7: Creating stored procedures...'

    -- Procedure: Update room status
    IF OBJECT_ID('dbo.sp_UpdateRoomStatus', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_UpdateRoomStatus

    EXEC('
    CREATE PROCEDURE [dbo].[sp_UpdateRoomStatus]
        @AccommodationID INT,
        @NewStatus NVARCHAR(30),
        @ChangedBy_ID SMALLINT = NULL,
        @ChangeReason NVARCHAR(500) = NULL,
        @Notes NVARCHAR(1000) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        BEGIN TRY
            BEGIN TRANSACTION

            DECLARE @RoomStatusID BIGINT
            DECLARE @PreviousStatus NVARCHAR(30)
            DECLARE @NewHousekeepingStatus NVARCHAR(30)
            DECLARE @NewOccupancyStatus NVARCHAR(30)
            DECLARE @NewIsOccupied BIT

            -- Get current status
            SELECT
                @RoomStatusID = ID,
                @PreviousStatus = CurrentStatus
            FROM Room_Status
            WHERE Accommodation_ID = @AccommodationID

            IF @RoomStatusID IS NULL
            BEGIN
                RAISERROR(''Room status not found for accommodation'', 16, 1)
                RETURN 1
            END

            -- Determine housekeeping and occupancy status from current status
            SET @NewHousekeepingStatus = CASE
                WHEN @NewStatus IN (''VACANT_CLEAN'', ''OCCUPIED_CLEAN'') THEN ''CLEAN''
                WHEN @NewStatus IN (''VACANT_DIRTY'', ''OCCUPIED_DIRTY'') THEN ''DIRTY''
                WHEN @NewStatus = ''OUT_OF_ORDER'' THEN ''CLEAN''
                WHEN @NewStatus = ''RESERVED'' THEN ''CLEAN''
                ELSE ''DIRTY''
            END

            SET @NewOccupancyStatus = CASE
                WHEN @NewStatus LIKE ''VACANT%'' THEN ''VACANT''
                WHEN @NewStatus LIKE ''OCCUPIED%'' THEN ''OCCUPIED''
                WHEN @NewStatus = ''RESERVED'' THEN ''RESERVED''
                WHEN @NewStatus = ''OUT_OF_ORDER'' THEN ''OUT_OF_ORDER''
                ELSE ''VACANT''
            END

            SET @NewIsOccupied = CASE
                WHEN @NewStatus LIKE ''OCCUPIED%'' THEN 1
                ELSE 0
            END

            -- Update room status
            UPDATE Room_Status
            SET
                CurrentStatus = @NewStatus,
                HousekeepingStatus = @NewHousekeepingStatus,
                OccupancyStatus = @NewOccupancyStatus,
                IsOccupied = @NewIsOccupied,
                LastStatusChange = GETDATE(),
                LastStatusChangedBy_ID = @ChangedBy_ID,
                Notes = COALESCE(@Notes, Notes)
            WHERE ID = @RoomStatusID

            -- Record in history
            INSERT INTO Room_Status_History (
                Room_Status_ID,
                Accommodation_ID,
                PreviousStatus,
                NewStatus,
                ChangedBy_ID,
                ChangeReason,
                Notes
            )
            VALUES (
                @RoomStatusID,
                @AccommodationID,
                @PreviousStatus,
                @NewStatus,
                @ChangedBy_ID,
                @ChangeReason,
                @Notes
            )

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

    PRINT '  ✓ Created sp_UpdateRoomStatus'

    -- Procedure: Mark room as cleaned
    IF OBJECT_ID('dbo.sp_MarkRoomCleaned', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_MarkRoomCleaned

    EXEC('
    CREATE PROCEDURE [dbo].[sp_MarkRoomCleaned]
        @AccommodationID INT,
        @CleanedBy_ID SMALLINT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        BEGIN TRY
            BEGIN TRANSACTION

            DECLARE @CurrentOccupancyStatus NVARCHAR(30)
            DECLARE @NewStatus NVARCHAR(30)

            -- Get current occupancy
            SELECT @CurrentOccupancyStatus = OccupancyStatus
            FROM Room_Status
            WHERE Accommodation_ID = @AccommodationID

            -- Determine new status based on occupancy
            SET @NewStatus = CASE
                WHEN @CurrentOccupancyStatus = ''OCCUPIED'' THEN ''OCCUPIED_CLEAN''
                ELSE ''VACANT_CLEAN''
            END

            -- Update room status
            UPDATE Room_Status
            SET
                CurrentStatus = @NewStatus,
                HousekeepingStatus = ''CLEAN'',
                LastCleanedDate = GETDATE(),
                LastCleanedBy_ID = @CleanedBy_ID,
                LastStatusChange = GETDATE(),
                LastStatusChangedBy_ID = @CleanedBy_ID
            WHERE Accommodation_ID = @AccommodationID

            -- Record in history
            INSERT INTO Room_Status_History (
                Room_Status_ID,
                Accommodation_ID,
                PreviousStatus,
                NewStatus,
                ChangedBy_ID,
                ChangeReason
            )
            SELECT
                ID,
                @AccommodationID,
                CurrentStatus,
                @NewStatus,
                @CleanedBy_ID,
                ''Room cleaned''
            FROM Room_Status
            WHERE Accommodation_ID = @AccommodationID

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

    PRINT '  ✓ Created sp_MarkRoomCleaned'

    -- Procedure: Check-in (update room status)
    IF OBJECT_ID('dbo.sp_CheckInUpdateRoomStatus', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_CheckInUpdateRoomStatus

    EXEC('
    CREATE PROCEDURE [dbo].[sp_CheckInUpdateRoomStatus]
        @AccommodationID INT,
        @ReservationID BIGINT,
        @GuestName NVARCHAR(200),
        @ExpectedCheckOutDate DATETIME,
        @ChangedBy_ID SMALLINT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        BEGIN TRY
            BEGIN TRANSACTION

            -- Update room status to occupied
            UPDATE Room_Status
            SET
                CurrentStatus = ''OCCUPIED_CLEAN'',
                HousekeepingStatus = ''CLEAN'',
                OccupancyStatus = ''OCCUPIED'',
                IsOccupied = 1,
                CurrentReservation_ID = @ReservationID,
                CurrentGuest_Name = @GuestName,
                CheckedInDate = GETDATE(),
                ExpectedCheckOutDate = @ExpectedCheckOutDate,
                LastStatusChange = GETDATE(),
                LastStatusChangedBy_ID = @ChangedBy_ID
            WHERE Accommodation_ID = @AccommodationID

            -- Record in history
            INSERT INTO Room_Status_History (
                Room_Status_ID,
                Accommodation_ID,
                PreviousStatus,
                NewStatus,
                ChangedBy_ID,
                ChangeReason,
                Reservation_ID
            )
            SELECT
                ID,
                @AccommodationID,
                CurrentStatus,
                ''OCCUPIED_CLEAN'',
                @ChangedBy_ID,
                ''Guest checked in'',
                @ReservationID
            FROM Room_Status
            WHERE Accommodation_ID = @AccommodationID

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

    PRINT '  ✓ Created sp_CheckInUpdateRoomStatus'

    -- Procedure: Check-out (update room status)
    IF OBJECT_ID('dbo.sp_CheckOutUpdateRoomStatus', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_CheckOutUpdateRoomStatus

    EXEC('
    CREATE PROCEDURE [dbo].[sp_CheckOutUpdateRoomStatus]
        @AccommodationID INT,
        @ChangedBy_ID SMALLINT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        BEGIN TRY
            BEGIN TRANSACTION

            DECLARE @ReservationID BIGINT

            -- Get current reservation
            SELECT @ReservationID = CurrentReservation_ID
            FROM Room_Status
            WHERE Accommodation_ID = @AccommodationID

            -- Update room status to vacant dirty
            UPDATE Room_Status
            SET
                CurrentStatus = ''VACANT_DIRTY'',
                HousekeepingStatus = ''DIRTY'',
                OccupancyStatus = ''VACANT'',
                IsOccupied = 0,
                CurrentReservation_ID = NULL,
                CurrentGuest_Name = NULL,
                CheckedInDate = NULL,
                ExpectedCheckOutDate = NULL,
                LastStatusChange = GETDATE(),
                LastStatusChangedBy_ID = @ChangedBy_ID
            WHERE Accommodation_ID = @AccommodationID

            -- Record in history
            INSERT INTO Room_Status_History (
                Room_Status_ID,
                Accommodation_ID,
                PreviousStatus,
                NewStatus,
                ChangedBy_ID,
                ChangeReason,
                Reservation_ID
            )
            SELECT
                ID,
                @AccommodationID,
                CurrentStatus,
                ''VACANT_DIRTY'',
                @ChangedBy_ID,
                ''Guest checked out'',
                @ReservationID
            FROM Room_Status
            WHERE Accommodation_ID = @AccommodationID

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

    PRINT '  ✓ Created sp_CheckOutUpdateRoomStatus'

    -- ===================================================================
    -- Step 8: Create views
    -- ===================================================================

    PRINT 'Step 8: Creating views...'

    IF OBJECT_ID('dbo.v_RoomStatusDashboard', 'V') IS NOT NULL
        DROP VIEW dbo.v_RoomStatusDashboard

    EXEC('
    CREATE VIEW [dbo].[v_RoomStatusDashboard]
    AS
    SELECT
        RS.ID AS RoomStatusID,
        A.ID AS AccommodationID,
        A.AccomName AS RoomName,
        A.AccomType,
        RS.CurrentStatus,
        RS.HousekeepingStatus,
        RS.OccupancyStatus,
        RS.IsOccupied,
        RS.CurrentReservation_ID,
        RS.CurrentGuest_Name,
        RS.CheckedInDate,
        RS.ExpectedCheckOutDate,
        RS.LastCleanedDate,
        E1.Name AS LastCleanedByName,
        RS.MaintenanceRequired,
        RS.MaintenanceNotes,
        RS.MaintenanceStartDate,
        RS.MaintenanceEndDate,
        RS.LastStatusChange,
        E2.Name AS LastStatusChangedByName,
        RS.Notes,
        A.Status AS AccommodationStatus
    FROM Room_Status RS
    INNER JOIN Accommodation A ON RS.Accommodation_ID = A.ID
    LEFT JOIN Employees E1 ON RS.LastCleanedBy_ID = E1.ID
    LEFT JOIN Employees E2 ON RS.LastStatusChangedBy_ID = E2.ID
    WHERE RS.IsActive = 1 AND RS.Status = 1 AND A.Status = 1
    ')

    PRINT '  ✓ Created v_RoomStatusDashboard'

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

    -- Check Room_Status table
    DECLARE @RoomStatusCount INT
    SELECT @RoomStatusCount = COUNT(*)
    FROM Room_Status

    PRINT '✓ Room_Status table contains ' + CAST(@RoomStatusCount AS VARCHAR) + ' record(s)'

    -- Check stored procedures
    DECLARE @SPCount INT
    SELECT @SPCount = COUNT(*)
    FROM sys.procedures
    WHERE name IN (
        'sp_UpdateRoomStatus',
        'sp_MarkRoomCleaned',
        'sp_CheckInUpdateRoomStatus',
        'sp_CheckOutUpdateRoomStatus'
    )

    IF @SPCount = 4
        PRINT '✓ All stored procedures created'
    ELSE
        PRINT '✗ Stored procedures verification failed'

    PRINT ''
    PRINT 'Room Status Types:'
    PRINT '  - VACANT_CLEAN: Ready for new guest'
    PRINT '  - VACANT_DIRTY: Needs cleaning'
    PRINT '  - OCCUPIED_CLEAN: Guest checked in, room clean'
    PRINT '  - OCCUPIED_DIRTY: Guest checked in, needs cleaning'
    PRINT '  - OUT_OF_ORDER: Under maintenance'
    PRINT '  - RESERVED: Reserved but not checked in'
    PRINT ''
    PRINT 'Next steps:'
    PRINT '  1. Integrate room status updates with check-in/check-out'
    PRINT '  2. Create housekeeping dashboard'
    PRINT '  3. Add room status indicators in UI'
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
IF OBJECT_ID('dbo.v_RoomStatusDashboard', 'V') IS NOT NULL
    DROP VIEW dbo.v_RoomStatusDashboard

-- Drop stored procedures
IF OBJECT_ID('dbo.sp_CheckOutUpdateRoomStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CheckOutUpdateRoomStatus

IF OBJECT_ID('dbo.sp_CheckInUpdateRoomStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CheckInUpdateRoomStatus

IF OBJECT_ID('dbo.sp_MarkRoomCleaned', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_MarkRoomCleaned

IF OBJECT_ID('dbo.sp_UpdateRoomStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateRoomStatus

-- Drop tables (CASCADE will handle FKs)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Room_Status_History]') AND type in (N'U'))
    DROP TABLE [dbo].[Room_Status_History]

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Room_Status]') AND type in (N'U'))
    DROP TABLE [dbo].[Room_Status]

-- Remove migration record
DELETE FROM Database_Migrations WHERE MigrationName = '06_Add_Room_Status_System'

COMMIT TRANSACTION

PRINT 'Rollback completed'

==============================================================*/
