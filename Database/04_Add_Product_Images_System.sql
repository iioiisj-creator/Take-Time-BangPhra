/*==============================================================
  Migration: 04_Add_Product_Images_System

  Purpose:
  - Add support for product images in reservation system
  - Enable product gallery with multiple images per product
  - Support image carousel/slider in reservation page
  - Track which products should show in reservation

  Features:
  - Product_Images table for storing product photos
  - Image ordering and status management
  - Product visibility flags
  - Image URL validation
  - Migration tracking and rollback support

  Author: Claude
  Date: 2025-11-03
  Dependencies: 00_Init_Migration_System
==============================================================*/

USE [Taketime]
GO

SET NOCOUNT ON;
SET XACT_ABORT ON; -- Rollback entire transaction on any error

DECLARE @MigrationName NVARCHAR(255) = '04_Add_Product_Images_System'
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

-- Check if Product table exists
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Product]') AND type in (N'U'))
BEGIN
    RAISERROR('✗ Product table does not exist. Cannot proceed.', 16, 1)
    GOTO MigrationEnd
END

PRINT '✓ Product table exists'

-- Check if ProductType table exists
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductType]') AND type in (N'U'))
BEGIN
    RAISERROR('✗ ProductType table does not exist. Cannot proceed.', 16, 1)
    GOTO MigrationEnd
END

PRINT '✓ ProductType table exists'

PRINT ''

-- ===================================================================
-- Begin Transaction
-- ===================================================================

BEGIN TRANSACTION

BEGIN TRY

    PRINT 'Starting database modifications...'
    PRINT ''

    -- ===================================================================
    -- Step 1: Create Product_Images table
    -- ===================================================================

    PRINT 'Step 1: Creating Product_Images table...'

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Product_Images]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[Product_Images](
            [ID] [bigint] IDENTITY(1,1) NOT NULL,
            [Product_ID] [int] NOT NULL,
            [ImageURL] [nvarchar](500) NOT NULL,
            [ImageTitle] [nvarchar](200) NULL,
            [ImageDescription] [nvarchar](500) NULL,
            [DisplayOrder] [int] NOT NULL DEFAULT 0,
            [IsActive] [bit] NOT NULL DEFAULT 1,
            [IsPrimary] [bit] NOT NULL DEFAULT 0,
            [UploadedDate] [datetime] NOT NULL DEFAULT GETDATE(),
            [UploadedBy_ID] [smallint] NULL,
            [FileSize] [int] NULL, -- in bytes
            [ImageWidth] [smallint] NULL, -- in pixels
            [ImageHeight] [smallint] NULL, -- in pixels
            [AltText] [nvarchar](200) NULL, -- for accessibility
            [Status] [tinyint] NOT NULL DEFAULT 1,
         CONSTRAINT [PK_Product_Images] PRIMARY KEY CLUSTERED
        (
            [ID] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY]

        PRINT '  ✓ Created Product_Images table'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ Product_Images table already exists'
    END

    -- ===================================================================
    -- Step 2: Add foreign key constraints
    -- ===================================================================

    PRINT 'Step 2: Adding foreign key constraints...'

    -- FK to Product table
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Product_Images_Product')
    BEGIN
        ALTER TABLE [dbo].[Product_Images]
        ADD CONSTRAINT [FK_Product_Images_Product]
        FOREIGN KEY([Product_ID])
        REFERENCES [dbo].[Product] ([ID])
        ON UPDATE CASCADE
        ON DELETE CASCADE

        PRINT '  ✓ Added FK_Product_Images_Product'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ FK_Product_Images_Product already exists'
    END

    -- FK to Employees (UploadedBy)
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Product_Images_Employees')
    BEGIN
        ALTER TABLE [dbo].[Product_Images]
        ADD CONSTRAINT [FK_Product_Images_Employees]
        FOREIGN KEY([UploadedBy_ID])
        REFERENCES [dbo].[Employees] ([ID])
        ON UPDATE NO ACTION
        ON DELETE SET NULL

        PRINT '  ✓ Added FK_Product_Images_Employees'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ FK_Product_Images_Employees already exists'
    END

    -- ===================================================================
    -- Step 3: Add check constraints
    -- ===================================================================

    PRINT 'Step 3: Adding check constraints...'

    -- DisplayOrder must be >= 0
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Product_Images_DisplayOrder')
    BEGIN
        ALTER TABLE [dbo].[Product_Images]
        ADD CONSTRAINT [CK_Product_Images_DisplayOrder] CHECK ([DisplayOrder] >= 0)

        PRINT '  ✓ Added CK_Product_Images_DisplayOrder'
    END

    -- Status must be 0 or 1
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Product_Images_Status')
    BEGIN
        ALTER TABLE [dbo].[Product_Images]
        ADD CONSTRAINT [CK_Product_Images_Status] CHECK ([Status] IN (0, 1))

        PRINT '  ✓ Added CK_Product_Images_Status'
    END

    -- FileSize must be positive
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Product_Images_FileSize')
    BEGIN
        ALTER TABLE [dbo].[Product_Images]
        ADD CONSTRAINT [CK_Product_Images_FileSize] CHECK ([FileSize] IS NULL OR [FileSize] > 0)

        PRINT '  ✓ Added CK_Product_Images_FileSize'
    END

    -- ImageWidth must be positive
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Product_Images_ImageWidth')
    BEGIN
        ALTER TABLE [dbo].[Product_Images]
        ADD CONSTRAINT [CK_Product_Images_ImageWidth] CHECK ([ImageWidth] IS NULL OR [ImageWidth] > 0)

        PRINT '  ✓ Added CK_Product_Images_ImageWidth'
    END

    -- ImageHeight must be positive
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Product_Images_ImageHeight')
    BEGIN
        ALTER TABLE [dbo].[Product_Images]
        ADD CONSTRAINT [CK_Product_Images_ImageHeight] CHECK ([ImageHeight] IS NULL OR [ImageHeight] > 0)

        PRINT '  ✓ Added CK_Product_Images_ImageHeight'
    END

    -- ===================================================================
    -- Step 4: Add indexes for performance
    -- ===================================================================

    PRINT 'Step 4: Creating performance indexes...'

    -- Index on Product_ID for faster lookups
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Product_Images_ProductID')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Product_Images_ProductID]
        ON [dbo].[Product_Images] ([Product_ID], [DisplayOrder])
        INCLUDE ([ImageURL], [IsPrimary], [IsActive])

        PRINT '  ✓ Created IX_Product_Images_ProductID'
    END

    -- Index for active images only
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Product_Images_Active')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Product_Images_Active]
        ON [dbo].[Product_Images] ([Product_ID], [IsActive], [DisplayOrder])
        WHERE [IsActive] = 1 AND [Status] = 1

        PRINT '  ✓ Created IX_Product_Images_Active'
    END

    -- Index for primary images
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Product_Images_Primary')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Product_Images_Primary]
        ON [dbo].[Product_Images] ([Product_ID], [IsPrimary])
        WHERE [IsPrimary] = 1 AND [IsActive] = 1

        PRINT '  ✓ Created IX_Product_Images_Primary'
    END

    -- ===================================================================
    -- Step 5: Add columns to Product table
    -- ===================================================================

    PRINT 'Step 5: Adding columns to Product table...'

    -- ShowInReservation flag
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Product]') AND name = 'ShowInReservation')
    BEGIN
        ALTER TABLE [dbo].[Product]
        ADD [ShowInReservation] [bit] NOT NULL DEFAULT 0

        PRINT '  ✓ Added ShowInReservation column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ ShowInReservation column already exists'
    END

    -- HasImages flag
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Product]') AND name = 'HasImages')
    BEGIN
        ALTER TABLE [dbo].[Product]
        ADD [HasImages] [bit] NOT NULL DEFAULT 0

        PRINT '  ✓ Added HasImages column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ HasImages column already exists'
    END

    -- ReservationDisplayOrder
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Product]') AND name = 'ReservationDisplayOrder')
    BEGIN
        ALTER TABLE [dbo].[Product]
        ADD [ReservationDisplayOrder] [int] NOT NULL DEFAULT 999

        PRINT '  ✓ Added ReservationDisplayOrder column'
    END
    ELSE
    BEGIN
        PRINT '  ⚠ ReservationDisplayOrder column already exists'
    END

    -- ===================================================================
    -- Step 6: Create stored procedures
    -- ===================================================================

    PRINT 'Step 6: Creating stored procedures...'

    -- Procedure: Get product images
    IF OBJECT_ID('dbo.sp_GetProductImages', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_GetProductImages

    EXEC('
    CREATE PROCEDURE [dbo].[sp_GetProductImages]
        @ProductID INT,
        @ActiveOnly BIT = 1
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            ID,
            Product_ID,
            ImageURL,
            ImageTitle,
            ImageDescription,
            DisplayOrder,
            IsActive,
            IsPrimary,
            UploadedDate,
            UploadedBy_ID,
            FileSize,
            ImageWidth,
            ImageHeight,
            AltText,
            Status
        FROM Product_Images
        WHERE Product_ID = @ProductID
          AND (@ActiveOnly = 0 OR (IsActive = 1 AND Status = 1))
        ORDER BY DisplayOrder ASC, IsPrimary DESC, ID ASC
    END
    ')

    PRINT '  ✓ Created sp_GetProductImages'

    -- Procedure: Get products for reservation gallery
    IF OBJECT_ID('dbo.sp_GetProductsForReservation', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_GetProductsForReservation

    EXEC('
    CREATE PROCEDURE [dbo].[sp_GetProductsForReservation]
        @ProductTypeID TINYINT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            P.ID,
            P.ProductName,
            P.ProductType_ID,
            PT.ProductTypeName,
            P.Price,
            P.Unit,
            P.Detail,
            P.ShowInReservation,
            P.HasImages,
            P.ReservationDisplayOrder,
            P.Status,
            (
                SELECT TOP 1 ImageURL
                FROM Product_Images
                WHERE Product_ID = P.ID
                  AND IsActive = 1
                  AND Status = 1
                ORDER BY IsPrimary DESC, DisplayOrder ASC
            ) AS PrimaryImageURL,
            (
                SELECT COUNT(*)
                FROM Product_Images
                WHERE Product_ID = P.ID
                  AND IsActive = 1
                  AND Status = 1
            ) AS ImageCount
        FROM Product P
        INNER JOIN ProductType PT ON P.ProductType_ID = PT.ID
        WHERE P.ShowInReservation = 1
          AND P.Status = 1
          AND PT.Status = 1
          AND (@ProductTypeID IS NULL OR P.ProductType_ID = @ProductTypeID)
        ORDER BY P.ReservationDisplayOrder ASC, P.ProductName ASC
    END
    ')

    PRINT '  ✓ Created sp_GetProductsForReservation'

    -- Procedure: Add product image
    IF OBJECT_ID('dbo.sp_AddProductImage', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_AddProductImage

    EXEC('
    CREATE PROCEDURE [dbo].[sp_AddProductImage]
        @ProductID INT,
        @ImageURL NVARCHAR(500),
        @ImageTitle NVARCHAR(200) = NULL,
        @ImageDescription NVARCHAR(500) = NULL,
        @DisplayOrder INT = 0,
        @IsPrimary BIT = 0,
        @UploadedBy_ID SMALLINT = NULL,
        @FileSize INT = NULL,
        @ImageWidth SMALLINT = NULL,
        @ImageHeight SMALLINT = NULL,
        @AltText NVARCHAR(200) = NULL,
        @ImageID BIGINT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        BEGIN TRY
            BEGIN TRANSACTION

            -- If this is set as primary, unset other primary images
            IF @IsPrimary = 1
            BEGIN
                UPDATE Product_Images
                SET IsPrimary = 0
                WHERE Product_ID = @ProductID
                  AND IsPrimary = 1
            END

            -- Insert new image
            INSERT INTO Product_Images (
                Product_ID,
                ImageURL,
                ImageTitle,
                ImageDescription,
                DisplayOrder,
                IsPrimary,
                UploadedBy_ID,
                FileSize,
                ImageWidth,
                ImageHeight,
                AltText
            )
            VALUES (
                @ProductID,
                @ImageURL,
                @ImageTitle,
                @ImageDescription,
                @DisplayOrder,
                @IsPrimary,
                @UploadedBy_ID,
                @FileSize,
                @ImageWidth,
                @ImageHeight,
                @AltText
            )

            SET @ImageID = SCOPE_IDENTITY()

            -- Update Product HasImages flag
            UPDATE Product
            SET HasImages = 1
            WHERE ID = @ProductID

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

    PRINT '  ✓ Created sp_AddProductImage'

    -- Procedure: Set primary image
    IF OBJECT_ID('dbo.sp_SetPrimaryProductImage', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_SetPrimaryProductImage

    EXEC('
    CREATE PROCEDURE [dbo].[sp_SetPrimaryProductImage]
        @ImageID BIGINT
    AS
    BEGIN
        SET NOCOUNT ON;

        BEGIN TRY
            BEGIN TRANSACTION

            DECLARE @ProductID INT

            SELECT @ProductID = Product_ID
            FROM Product_Images
            WHERE ID = @ImageID

            IF @ProductID IS NULL
            BEGIN
                RAISERROR(''Image not found'', 16, 1)
                RETURN 1
            END

            -- Unset all primary images for this product
            UPDATE Product_Images
            SET IsPrimary = 0
            WHERE Product_ID = @ProductID

            -- Set this image as primary
            UPDATE Product_Images
            SET IsPrimary = 1
            WHERE ID = @ImageID

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

    PRINT '  ✓ Created sp_SetPrimaryProductImage'

    -- ===================================================================
    -- Step 7: Create view for product gallery
    -- ===================================================================

    PRINT 'Step 7: Creating views...'

    IF OBJECT_ID('dbo.v_ProductGallery', 'V') IS NOT NULL
        DROP VIEW dbo.v_ProductGallery

    EXEC('
    CREATE VIEW [dbo].[v_ProductGallery]
    AS
    SELECT
        P.ID AS ProductID,
        P.ProductName,
        P.ProductType_ID,
        PT.ProductTypeName,
        P.Price,
        P.Unit,
        P.Detail AS ProductDetail,
        P.ShowInReservation,
        P.ReservationDisplayOrder,
        P.HasImages,
        P.Status AS ProductStatus,
        PI.ID AS ImageID,
        PI.ImageURL,
        PI.ImageTitle,
        PI.ImageDescription,
        PI.DisplayOrder AS ImageDisplayOrder,
        PI.IsPrimary,
        PI.IsActive AS ImageIsActive,
        PI.UploadedDate,
        PI.FileSize,
        PI.ImageWidth,
        PI.ImageHeight,
        PI.AltText,
        E.Name AS UploadedByName
    FROM Product P
    INNER JOIN ProductType PT ON P.ProductType_ID = PT.ID
    LEFT JOIN Product_Images PI ON P.ID = PI.Product_ID AND PI.IsActive = 1 AND PI.Status = 1
    LEFT JOIN Employees E ON PI.UploadedBy_ID = E.ID
    WHERE P.Status = 1
    ')

    PRINT '  ✓ Created v_ProductGallery'

    -- ===================================================================
    -- Step 8: Insert sample data (for testing)
    -- ===================================================================

    PRINT 'Step 8: Setting up sample configuration...'

    -- Mark specific products to show in reservation (example: หมูกระทะ, ไวน์)
    -- This is just a placeholder - admin will configure actual products
    UPDATE Product
    SET ShowInReservation = 0, -- Default to not showing
        ReservationDisplayOrder = 999
    WHERE Status = 1

    PRINT '  ✓ Product ShowInReservation defaults set'
    PRINT '  ℹ Admin should configure which products to show in reservation'

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

    -- Check Product_Images table
    DECLARE @ImageCount INT
    SELECT @ImageCount = COUNT(*)
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Product_Images]')
      AND type in (N'U')

    IF @ImageCount = 1
        PRINT '✓ Product_Images table exists'
    ELSE
        PRINT '✗ Product_Images table verification failed'

    -- Check new Product columns
    DECLARE @ColCount INT
    SELECT @ColCount = COUNT(*)
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Product]')
      AND name IN ('ShowInReservation', 'HasImages', 'ReservationDisplayOrder')

    IF @ColCount = 3
        PRINT '✓ Product table columns added successfully'
    ELSE
        PRINT '✗ Product table columns verification failed'

    -- Check stored procedures
    DECLARE @SPCount INT
    SELECT @SPCount = COUNT(*)
    FROM sys.procedures
    WHERE name IN ('sp_GetProductImages', 'sp_GetProductsForReservation', 'sp_AddProductImage', 'sp_SetPrimaryProductImage')

    IF @SPCount = 4
        PRINT '✓ All stored procedures created'
    ELSE
        PRINT '✗ Stored procedures verification failed'

    PRINT ''
    PRINT 'Next steps:'
    PRINT '  1. Configure products to show in reservation gallery'
    PRINT '  2. Upload product images via admin interface'
    PRINT '  3. Test product gallery in reservation page'
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
IF OBJECT_ID('dbo.v_ProductGallery', 'V') IS NOT NULL
    DROP VIEW dbo.v_ProductGallery

-- Drop stored procedures
IF OBJECT_ID('dbo.sp_SetPrimaryProductImage', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_SetPrimaryProductImage

IF OBJECT_ID('dbo.sp_AddProductImage', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AddProductImage

IF OBJECT_ID('dbo.sp_GetProductsForReservation', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetProductsForReservation

IF OBJECT_ID('dbo.sp_GetProductImages', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetProductImages

-- Drop Product columns
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Product]') AND name = 'ReservationDisplayOrder')
    ALTER TABLE [dbo].[Product] DROP COLUMN [ReservationDisplayOrder]

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Product]') AND name = 'HasImages')
    ALTER TABLE [dbo].[Product] DROP COLUMN [HasImages]

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Product]') AND name = 'ShowInReservation')
    ALTER TABLE [dbo].[Product] DROP COLUMN [ShowInReservation]

-- Drop Product_Images table (CASCADE will handle FKs)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Product_Images]') AND type in (N'U'))
    DROP TABLE [dbo].[Product_Images]

-- Remove migration record
DELETE FROM Database_Migrations WHERE MigrationName = '04_Add_Product_Images_System'

COMMIT TRANSACTION

PRINT 'Rollback completed'

==============================================================*/
