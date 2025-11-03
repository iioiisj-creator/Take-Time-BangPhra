/*==============================================================
  Initialize Database Migration System

  Purpose:
  - Track which migrations have been applied
  - Prevent duplicate migrations
  - Allow version control of database changes

  Run this FIRST before any other migrations!
==============================================================*/

USE [Taketime]
GO

PRINT '============================================================='
PRINT 'Initializing Database Migration System'
PRINT '============================================================='
GO

-- ===================================================================
-- Create Database_Migrations table to track applied migrations
-- ===================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Database_Migrations]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Database_Migrations](
        [ID] [int] IDENTITY(1,1) NOT NULL,
        [MigrationName] [nvarchar](255) NOT NULL,
        [AppliedDate] [datetime] NOT NULL,
        [AppliedBy] [nvarchar](100) NULL,
        [ScriptContent] [ntext] NULL,
        [Success] [bit] NOT NULL,
        [ErrorMessage] [ntext] NULL,
        [ExecutionTimeMs] [int] NULL,
     CONSTRAINT [PK_Database_Migrations] PRIMARY KEY CLUSTERED
    (
        [ID] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

    PRINT '✓ Created table: Database_Migrations'
END
ELSE
BEGIN
    PRINT '✓ Table already exists: Database_Migrations'
END
GO

-- Add default constraint for AppliedDate
IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_Database_Migrations_AppliedDate')
BEGIN
    ALTER TABLE [dbo].[Database_Migrations]
    ADD CONSTRAINT [DF_Database_Migrations_AppliedDate] DEFAULT (GETDATE()) FOR [AppliedDate]

    PRINT '✓ Added default constraint for AppliedDate'
END
GO

-- Add default constraint for Success
IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_Database_Migrations_Success')
BEGIN
    ALTER TABLE [dbo].[Database_Migrations]
    ADD CONSTRAINT [DF_Database_Migrations_Success] DEFAULT ((1)) FOR [Success]

    PRINT '✓ Added default constraint for Success'
END
GO

-- ===================================================================
-- Create stored procedure to check if migration was applied
-- ===================================================================

IF OBJECT_ID('dbo.sp_IsMigrationApplied', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_IsMigrationApplied
GO

CREATE PROCEDURE [dbo].[sp_IsMigrationApplied]
    @MigrationName NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM Database_Migrations
        WHERE MigrationName = @MigrationName
          AND Success = 1
    )
        SELECT 1 AS IsApplied
    ELSE
        SELECT 0 AS IsApplied
END
GO

PRINT '✓ Created stored procedure: sp_IsMigrationApplied'
GO

-- ===================================================================
-- Create stored procedure to record migration
-- ===================================================================

IF OBJECT_ID('dbo.sp_RecordMigration', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RecordMigration
GO

CREATE PROCEDURE [dbo].[sp_RecordMigration]
    @MigrationName NVARCHAR(255),
    @AppliedBy NVARCHAR(100) = NULL,
    @ScriptContent NTEXT = NULL,
    @Success BIT = 1,
    @ErrorMessage NTEXT = NULL,
    @ExecutionTimeMs INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Database_Migrations
        (MigrationName, AppliedBy, ScriptContent, Success, ErrorMessage, ExecutionTimeMs)
    VALUES
        (@MigrationName, @AppliedBy, @ScriptContent, @Success, @ErrorMessage, @ExecutionTimeMs)

    IF @Success = 1
        PRINT '✓ Migration recorded: ' + @MigrationName
    ELSE
        PRINT '✗ Migration failed: ' + @MigrationName
END
GO

PRINT '✓ Created stored procedure: sp_RecordMigration'
GO

-- ===================================================================
-- Create view to see migration history
-- ===================================================================

IF OBJECT_ID('dbo.v_MigrationHistory', 'V') IS NOT NULL
    DROP VIEW dbo.v_MigrationHistory
GO

CREATE VIEW [dbo].[v_MigrationHistory]
AS
SELECT
    ID,
    MigrationName,
    AppliedDate,
    AppliedBy,
    Success,
    ErrorMessage,
    ExecutionTimeMs,
    CASE
        WHEN Success = 1 THEN '✓ Success'
        ELSE '✗ Failed'
    END AS Status
FROM Database_Migrations
GO

PRINT '✓ Created view: v_MigrationHistory'
GO

-- ===================================================================
-- Record this initialization as the first migration
-- ===================================================================

EXEC sp_RecordMigration
    @MigrationName = '00_Init_Migration_System',
    @AppliedBy = SYSTEM_USER,
    @Success = 1,
    @ExecutionTimeMs = 0
GO

PRINT ''
PRINT '============================================================='
PRINT 'Migration System Initialized Successfully!'
PRINT '============================================================='
PRINT ''
PRINT 'Available commands:'
PRINT '  - View history: SELECT * FROM v_MigrationHistory'
PRINT '  - Check migration: EXEC sp_IsMigrationApplied ''migration_name'''
PRINT '  - Record migration: EXEC sp_RecordMigration ''migration_name'', ''user'''
PRINT ''
GO

-- Display current migration status
SELECT * FROM v_MigrationHistory
GO
