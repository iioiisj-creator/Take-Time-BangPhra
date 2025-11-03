USE [master]
GO
/****** Object:  Database [Taketime]    Script Date: 10/29/2025 3:16:27 PM ******/
CREATE DATABASE [Taketime]
 CONTAINMENT = NONE
 ON  PRIMARY
( NAME = N'taketime_Data', FILENAME = N'D:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\taketime_new.mdf' , SIZE = 34816KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON
( NAME = N'taketime_Log', FILENAME = N'D:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\taketime_new.ldf' , SIZE = 811584KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [Taketime] SET COMPATIBILITY_LEVEL = 130
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Taketime].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Taketime] SET ANSI_NULL_DEFAULT OFF
GO
ALTER DATABASE [Taketime] SET ANSI_NULLS OFF
GO
ALTER DATABASE [Taketime] SET ANSI_PADDING OFF
GO
ALTER DATABASE [Taketime] SET ANSI_WARNINGS OFF
GO
ALTER DATABASE [Taketime] SET ARITHABORT OFF
GO
ALTER DATABASE [Taketime] SET AUTO_CLOSE OFF
GO
ALTER DATABASE [Taketime] SET AUTO_SHRINK OFF
GO
ALTER DATABASE [Taketime] SET AUTO_UPDATE_STATISTICS ON
GO
ALTER DATABASE [Taketime] SET CURSOR_CLOSE_ON_COMMIT OFF
GO
ALTER DATABASE [Taketime] SET CURSOR_DEFAULT  GLOBAL
GO
ALTER DATABASE [Taketime] SET CONCAT_NULL_YIELDS_NULL OFF
GO
ALTER DATABASE [Taketime] SET NUMERIC_ROUNDABORT OFF
GO
ALTER DATABASE [Taketime] SET QUOTED_IDENTIFIER OFF
GO
ALTER DATABASE [Taketime] SET RECURSIVE_TRIGGERS OFF
GO
ALTER DATABASE [Taketime] SET  DISABLE_BROKER
GO
ALTER DATABASE [Taketime] SET AUTO_UPDATE_STATISTICS_ASYNC OFF
GO
ALTER DATABASE [Taketime] SET DATE_CORRELATION_OPTIMIZATION OFF
GO
ALTER DATABASE [Taketime] SET TRUSTWORTHY OFF
GO
ALTER DATABASE [Taketime] SET ALLOW_SNAPSHOT_ISOLATION OFF
GO
ALTER DATABASE [Taketime] SET PARAMETERIZATION SIMPLE
GO
ALTER DATABASE [Taketime] SET READ_COMMITTED_SNAPSHOT OFF
GO
ALTER DATABASE [Taketime] SET HONOR_BROKER_PRIORITY OFF
GO
ALTER DATABASE [Taketime] SET RECOVERY FULL
GO
ALTER DATABASE [Taketime] SET  MULTI_USER
GO
ALTER DATABASE [Taketime] SET PAGE_VERIFY CHECKSUM
GO
ALTER DATABASE [Taketime] SET DB_CHAINING OFF
GO
ALTER DATABASE [Taketime] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF )
GO
ALTER DATABASE [Taketime] SET TARGET_RECOVERY_TIME = 60 SECONDS
GO
ALTER DATABASE [Taketime] SET DELAYED_DURABILITY = DISABLED
GO
ALTER DATABASE [Taketime] SET QUERY_STORE = OFF
GO
USE [Taketime]
GO
/****** Object:  Table [dbo].[Accommodation]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Accommodation](
	[ID] [tinyint] IDENTITY(1,1) NOT NULL,
	[AccomName] [nvarchar](500) NOT NULL,
	[People] [tinyint] NOT NULL,
	[LimitWithPeople] [bit] NOT NULL,
	[Price] [smallint] NULL,
	[Status] [bit] NOT NULL,
	[OrderID] [tinyint] NULL,
	[ProductType_ID] [tinyint] NOT NULL,
	[Unit] [nvarchar](50) NULL,
	[AccomGroupID] [tinyint] NULL,
 CONSTRAINT [PK_Accommodation] PRIMARY KEY CLUSTERED
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Accommodation_DayType]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Accommodation_DayType](
	[ID] [tinyint] IDENTITY(1,1) NOT NULL,
	[DayType_Name] [nvarchar](50) NOT NULL,
	[Day] [nvarchar](100) NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Accommodation_Holiday]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Accommodation_Holiday](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Holiday_Date] [date] NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Accommodation_HolidayPrice]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Accommodation_HolidayPrice](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Accommodation_ID] [tinyint] NOT NULL,
	[DateNewPrice] [date] NOT NULL,
	[Price] [int] NOT NULL,
	[Remark] [ntext] NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Accommodation_RatePlan]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Accommodation_RatePlan](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[Accom_ID] [tinyint] NOT NULL,
	[DayType_Name_ID] [tinyint] NOT NULL,
	[Start_Month] [tinyint] NOT NULL,
	[End_Month] [tinyint] NOT NULL,
	[Price] [int] NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Accommodation_RatePlan_Group]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Accommodation_RatePlan_Group](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[GroupID] [smallint] NOT NULL,
	[Group_Name] [nvarchar](200) NOT NULL,
	[RatePlan_ID] [smallint] NOT NULL,
	[Status] [bit] NOT NULL,
	[AccomGroupID] [tinyint] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Account_Paid_How]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Account_Paid_How](
	[ID] [tinyint] IDENTITY(1,1) NOT NULL,
	[Paid_How] [nvarchar](50) NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Account_Paid_Type]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Account_Paid_Type](
	[ID] [tinyint] IDENTITY(1,1) NOT NULL,
	[Paid_Type] [nvarchar](500) NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Account_Payment]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Account_Payment](
	[ID] [nvarchar](15) NOT NULL,
	[Vendor_ID] [bigint] NOT NULL,
	[Created_Date] [date] NOT NULL,
	[Total_Amount] [float] NOT NULL,
	[Vat_Type_ID] [tinyint] NOT NULL,
	[Vat] [float] NOT NULL,
	[Total_Amount_Exclude_Vat] [float] NOT NULL,
	[Paid_How] [nvarchar](50) NOT NULL,
	[Paid_Type] [nvarchar](50) NOT NULL,
	[Status] [nvarchar](50) NOT NULL,
	[Created_By_ID] [smallint] NOT NULL,
	[UID] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Account_Payment] PRIMARY KEY CLUSTERED
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Account_Payment_Detail]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Account_Payment_Detail](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Payment_ID] [nvarchar](15) NOT NULL,
	[Number] [tinyint] NOT NULL,
	[Detail] [nvarchar](1000) NOT NULL,
	[Amount] [float] NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Account_ProductType]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Account_ProductType](
	[ID] [tinyint] NOT NULL,
	[ProductType_Name] [nvarchar](500) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Account_Receipt]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Account_Receipt](
	[ID] [nvarchar](15) NOT NULL,
	[Reservation_ID] [bigint] NULL,
	[Created_Date] [date] NOT NULL,
	[Total_Amount] [float] NOT NULL,
	[Vat] [float] NOT NULL,
	[Total_Amount_Exclude_Vat] [float] NOT NULL,
	[IsDeposit] [bit] NULL,
	[UseDeposit] [bit] NULL,
	[Paid_Type] [nvarchar](50) NULL,
	[Status] [nvarchar](50) NULL,
	[Created_By_ID] [smallint] NULL,
	[Etax] [bit] NULL,
	[Customer_ID] [bigint] NULL,
	[UID] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Account_Receipt] PRIMARY KEY CLUSTERED
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Account_Receipt_Detail]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Account_Receipt_Detail](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [tinyint] NOT NULL,
	[Receipt_ID] [nvarchar](15) NOT NULL,
	[ProductType_ID] [tinyint] NOT NULL,
	[Product_ID] [tinyint] NOT NULL,
	[Product_Data] [nvarchar](500) NOT NULL,
	[Product_Amount] [float] NOT NULL,
	[Product_Unit] [nvarchar](50) NOT NULL,
	[Price_PerPeice] [float] NOT NULL,
	[Price_Amount] [float] NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Account_Vat_Type]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Account_Vat_Type](
	[ID] [tinyint] IDENTITY(1,1) NOT NULL,
	[Vat_Type] [nvarchar](50) NOT NULL,
	[Vat_Percent] [smallint] NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Address]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Address](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[PostalCode] [nvarchar](50) NOT NULL,
	[Province] [nvarchar](100) NOT NULL,
	[District] [nvarchar](100) NOT NULL,
	[SubDistrict] [nvarchar](100) NOT NULL,
	[Address_Code] [nvarchar](8) NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Admin]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Admin](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[Username] [nvarchar](50) NULL,
	[Password] [nvarchar](50) NULL,
	[Role] [nvarchar](50) NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[Address] [nvarchar](1000) NULL,
	[IDNumber] [nchar](13) NULL,
	[StartDate] [date] NULL,
	[Salary] [smallint] NULL,
	[IsCEO] [bit] NOT NULL,
	[Status] [bit] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Affiliate_Discount]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Affiliate_Discount](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[Discount_Name] [nvarchar](50) NOT NULL,
	[Discount_Amount] [int] NOT NULL,
	[IncentivePercent] [tinyint] NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Affiliate_Discount_RatePlan]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Affiliate_Discount_RatePlan](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Affiliate_Discount_ID] [smallint] NOT NULL,
	[Accommodation_RatePlan_ID] [smallint] NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Affiliate_Member]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Affiliate_Member](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[ID_Number] [nchar](13) NOT NULL,
	[Password] [nvarchar](50) NOT NULL,
	[Register_Date] [datetime] NOT NULL,
	[Vendor_ID] [bigint] NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[Coupon_Code] [nchar](8) NOT NULL,
	[Bank_Code] [nvarchar](10) NOT NULL,
	[Bank_Number] [nvarchar](13) NOT NULL,
	[Affiliate_Discount_ID] [smallint] NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Affiliate_Reservation]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Affiliate_Reservation](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Affiliate_Member_Coupon_Code] [nchar](8) NOT NULL,
	[Reservation_ID] [bigint] NOT NULL,
	[Accommodation_ID] [tinyint] NOT NULL,
	[Affiliate_Discount_RatePlan_ID] [int] NOT NULL,
	[PriceAfterDiscount] [int] NOT NULL,
	[Commission] [float] NOT NULL,
	[StayDate] [date] NOT NULL,
	[Status] [nvarchar](10) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Affiliate_Reservation_Payment]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Affiliate_Reservation_Payment](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Affiliate_Reservation_ID] [bigint] NOT NULL,
	[Account_Payment_ID] [bigint] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Assets]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Assets](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Received_Date] [date] NOT NULL,
	[Payment_Number] [nvarchar](12) NULL,
	[Receipt_Number] [nvarchar](50) NULL,
	[Seller] [nvarchar](100) NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Amount] [int] NOT NULL,
	[PricePerPiece] [int] NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Business_Info]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Business_Info](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Business_Type_ID] [smallint] NOT NULL,
	[Company_Name] [nvarchar](500) NULL,
	[Address] [nvarchar](16) NULL,
	[Address_ID] [int] NULL,
	[Email] [nvarchar](100) NULL,
	[LegalEntity_Number] [nvarchar](13) NULL,
	[Branch_Number] [nvarchar](5) NULL,
	[Phone_Number] [nvarchar](50) NULL,
	[Use_Vat] [bit] NOT NULL,
	[Status] [bit] NOT NULL,
	[Address1] [nvarchar](200) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Customer]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customer](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MobilePhone] [nvarchar](30) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[NickName] [nvarchar](50) NULL,
	[ComeFrom] [nvarchar](50) NULL,
	[Remark] [nvarchar](500) NULL,
	[Status] [bit] NOT NULL,
	[FullName] [nvarchar](500) NULL,
	[Address] [nvarchar](1000) NULL,
	[Address1] [nvarchar](200) NULL,
	[Address_ID] [int] NULL,
	[IDNumber] [nvarchar](13) NULL,
	[Email] [nvarchar](100) NULL,
	[Customer_Type_ID] [smallint] NULL,
	[Branch_Number] [nvarchar](50) NULL,
 CONSTRAINT [PK_Customer_1] PRIMARY KEY CLUSTERED
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Customer_Type]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customer_Type](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[Customer_Type] [nvarchar](50) NOT NULL,
	[Customer_Code] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Items]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Items](
	[ID] [tinyint] NOT NULL,
	[ItemName] [nvarchar](500) NOT NULL,
	[Amount] [tinyint] NOT NULL,
	[LimitWithAmount] [bit] NOT NULL,
	[Price] [smallint] NOT NULL,
	[Status] [bit] NOT NULL,
	[OrderID] [tinyint] NULL,
	[ProductType_ID] [tinyint] NOT NULL,
	[Unit] [nvarchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Logs]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Logs](
	[LogDateTime] [datetime] NOT NULL,
	[LogAction] [nvarchar](200) NOT NULL,
	[LogDetail] [ntext] NOT NULL,
	[LogBy] [nvarchar](100) NOT NULL,
	[LogFromComputerName] [nvarchar](100) NULL,
	[LogFromIP] [nvarchar](100) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Logs_Access]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Logs_Access](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[AccessDateTime] [datetime] NULL,
	[DeviceName] [nvarchar](500) NULL,
	[DeviceIP] [nvarchar](50) NULL,
	[Browser] [nvarchar](100) NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MapDataWithSTAAH]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MapDataWithSTAAH](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Agency] [nvarchar](50) NOT NULL,
	[ROOM_TYPE] [nvarchar](100) NOT NULL,
	[Accommodation_ID] [tinyint] NOT NULL,
	[Remark] [nvarchar](200) NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Product]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Product](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Barcode] [nvarchar](50) NULL,
	[Category_ID] [tinyint] NULL,
	[Product_Name] [nvarchar](100) NULL,
	[Sell_Price] [float] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Product_Category]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Product_Category](
	[ID] [tinyint] IDENTITY(1,1) NOT NULL,
	[Category_Name] [nvarchar](50) NOT NULL,
	[Status] [bit] NOT NULL,
 CONSTRAINT [PK_Product_Category] PRIMARY KEY CLUSTERED
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Product_In]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Product_In](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[DateTime_In] [datetime] NOT NULL,
	[Product_ID] [int] NOT NULL,
	[Amount] [int] NOT NULL,
	[PricePerUnit] [float] NOT NULL,
 CONSTRAINT [PK_Product_In] PRIMARY KEY CLUSTERED
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Product_Out]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Product_Out](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[DateTime_Out] [datetime] NOT NULL,
	[Product_ID] [int] NOT NULL,
	[Amount] [int] NOT NULL,
	[PricePerUnit] [float] NOT NULL,
	[Account_Receipt_ID] [nvarchar](15) NULL,
	[Account_Paid_How_ID] [tinyint] NULL,
	[Remark] [nvarchar](100) NULL,
 CONSTRAINT [PK_Product_Out] PRIMARY KEY CLUSTERED
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Reservation]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Reservation](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Customer_MobilePhone] [nvarchar](30) NOT NULL,
	[CheckinDate] [date] NOT NULL,
	[CheckoutDate] [date] NOT NULL,
	[StayDays] [tinyint] NOT NULL,
	[Status] [nvarchar](50) NULL,
	[TotalPrice] [int] NULL,
	[Deposit] [int] NULL,
	[Remark] [nvarchar](500) NULL,
	[Reserve_By] [nvarchar](50) NULL,
	[Created_Date] [datetime] NULL,
	[NoCreateReceipt] [bit] NULL,
	[NoNameinReceipt] [bit] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Reservation_Accommodation]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Reservation_Accommodation](
	[Reservation_ID] [bigint] NOT NULL,
	[Accommodation_ID] [tinyint] NOT NULL,
	[Amount] [tinyint] NULL,
	[Price] [int] NULL,
	[Use_Coupon] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Reservation_Items]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Reservation_Items](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Reservation_ID] [bigint] NOT NULL,
	[Items_ID] [tinyint] NOT NULL,
	[Amount] [tinyint] NOT NULL,
	[Price] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Reviews]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Reviews](
	[Date] [datetime] NOT NULL,
	[json] [ntext] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Vendor]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Vendor](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[IDNumber] [nvarchar](13) NOT NULL,
	[Vendor_Type_ID] [smallint] NULL,
	[Name] [nvarchar](500) NOT NULL,
	[Address] [nvarchar](1000) NOT NULL,
	[Address1] [nvarchar](200) NULL,
	[Address_ID] [int] NULL,
	[Phone_Number] [nvarchar](30) NOT NULL,
	[Vendor_Group] [nvarchar](50) NULL,
	[Status] [bit] NOT NULL,
	[Branch_Number] [nvarchar](10) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Voucher]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Voucher](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Voucher_Number] [nvarchar](13) NOT NULL,
	[Sell_Price] [float] NOT NULL,
	[Created_Date] [datetime] NOT NULL,
	[Used_Status] [bit] NOT NULL,
	[Used_Date] [datetime] NULL,
	[Reservation_ID] [bigint] NULL,
	[Customer_ID] [bigint] NULL,
	[Receipt_ID] [nchar](15) NULL,
	[Remark] [ntext] NULL,
	[Status] [bit] NOT NULL,
	[Expired_Date] [date] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Voucher_RatePlan_Group]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Voucher_RatePlan_Group](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Voucher_Number] [nvarchar](13) NOT NULL,
	[RatePlan_GroupID] [smallint] NOT NULL,
	[PriceTo] [float] NOT NULL,
	[Status] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Accommodation] ADD  CONSTRAINT [DF_Accommodation_LimitWithPeople]  DEFAULT ((0)) FOR [LimitWithPeople]
GO
ALTER TABLE [dbo].[Accommodation] ADD  CONSTRAINT [DF_Accommodation_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Accommodation] ADD  CONSTRAINT [DF_Accommodation_ProductType_ID]  DEFAULT ((1)) FOR [ProductType_ID]
GO
ALTER TABLE [dbo].[Accommodation_DayType] ADD  CONSTRAINT [DF_Accommodation_DayType_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Accommodation_Holiday] ADD  CONSTRAINT [DF_Accommodation_Holiday_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Accommodation_HolidayPrice] ADD  CONSTRAINT [DF_Accommodation_HolidayPrice_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Accommodation_RatePlan] ADD  CONSTRAINT [DF_Accommodation_RatePlan_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Accommodation_RatePlan_Group] ADD  CONSTRAINT [DF_Accommodation_RatePlan_Group_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Account_Paid_How] ADD  CONSTRAINT [DF_Account_Paid_Type_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Account_Paid_Type] ADD  CONSTRAINT [DF_Account_Paid_Type_Status_1]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Account_Payment] ADD  CONSTRAINT [DF_Account_Payment_UID]  DEFAULT (newid()) FOR [UID]
GO
ALTER TABLE [dbo].[Account_Payment_Detail] ADD  CONSTRAINT [DF_Account_Payment_Detail_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Account_Receipt] ADD  CONSTRAINT [DF_Account_Receipt_Etax]  DEFAULT ((0)) FOR [Etax]
GO
ALTER TABLE [dbo].[Account_Receipt] ADD  CONSTRAINT [DF_Account_Receipt_UID]  DEFAULT (newid()) FOR [UID]
GO
ALTER TABLE [dbo].[Account_Receipt_Detail] ADD  CONSTRAINT [DF_Account_Receipt_Detail_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Account_Vat_Type] ADD  CONSTRAINT [DF_Account_Vat_Type_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Address] ADD  CONSTRAINT [DF_Address_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Admin] ADD  CONSTRAINT [DF_Admin_IsCEO]  DEFAULT ((0)) FOR [IsCEO]
GO
ALTER TABLE [dbo].[Admin] ADD  CONSTRAINT [DF_Admin_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Affiliate_Discount] ADD  CONSTRAINT [DF_Affiliate_Discount_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Affiliate_Discount_RatePlan] ADD  CONSTRAINT [DF_Affiliate_Discount_RatePlan_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Affiliate_Member] ADD  CONSTRAINT [DF_Affiliate_Member_Affiliate_Discount_ID]  DEFAULT ((1)) FOR [Affiliate_Discount_ID]
GO
ALTER TABLE [dbo].[Affiliate_Member] ADD  CONSTRAINT [DF_Affiliate_Member_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Affiliate_Reservation] ADD  CONSTRAINT [DF_Affiliate_Member_Reservation_Status]  DEFAULT (N'NEW') FOR [Status]
GO
ALTER TABLE [dbo].[Assets] ADD  CONSTRAINT [DF_Assets_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Business_Info] ADD  CONSTRAINT [DF_Business_Info_Use_Vat]  DEFAULT ((1)) FOR [Use_Vat]
GO
ALTER TABLE [dbo].[Business_Info] ADD  CONSTRAINT [DF_Business_Info_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Customer] ADD  CONSTRAINT [DF_Customer_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Items] ADD  CONSTRAINT [DF_Rental_Items_LimitWithAmount]  DEFAULT ((1)) FOR [LimitWithAmount]
GO
ALTER TABLE [dbo].[Items] ADD  CONSTRAINT [DF_Rental_Items_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Items] ADD  CONSTRAINT [DF_Items_ProductType_ID]  DEFAULT ((2)) FOR [ProductType_ID]
GO
ALTER TABLE [dbo].[Logs_Access] ADD  CONSTRAINT [DF_Logs_Access_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[MapDataWithSTAAH] ADD  CONSTRAINT [DF_MapDataWithSTAAH_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Product] ADD  CONSTRAINT [DF_Product_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Product_Category] ADD  CONSTRAINT [DF_Product_Status_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Reservation_Accommodation] ADD  CONSTRAINT [DF_Reservation_Accommodation_Use_Coupon]  DEFAULT ((0)) FOR [Use_Coupon]
GO
ALTER TABLE [dbo].[Vendor] ADD  CONSTRAINT [DF_Vendor_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Voucher] ADD  CONSTRAINT [DF_Voucher_Used_Status]  DEFAULT ((0)) FOR [Used_Status]
GO
ALTER TABLE [dbo].[Voucher] ADD  CONSTRAINT [DF_Voucher_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Voucher_RatePlan_Group] ADD  CONSTRAINT [DF_Voucher_RatePlan_Group_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Product_Category]  WITH CHECK ADD  CONSTRAINT [FK_Product_Category_Product_Category] FOREIGN KEY([ID])
REFERENCES [dbo].[Product_Category] ([ID])
GO
ALTER TABLE [dbo].[Product_Category] CHECK CONSTRAINT [FK_Product_Category_Product_Category]
GO
/****** Object:  StoredProcedure [dbo].[sp_CalculateAccommodationRevenue]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Stored Procedure สำหรับคำนวณรายได้ค่าห้องพัก
CREATE PROCEDURE [dbo].[sp_CalculateAccommodationRevenue]
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    SELECT
        ISNULL(SUM(RA.Price * R.StayDays), 0) as TotalRevenue,
        ISNULL(SUM(R.Deposit), 0) as TotalDeposit
    FROM [Reservation] R
    INNER JOIN Reservation_Accommodation RA ON RA.Reservation_ID = R.ID
    WHERE R.CheckinDate >= @StartDate AND R.CheckoutDate <= @EndDate
    AND R.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')
END
GO
/****** Object:  StoredProcedure [dbo].[sp_CalculateMonthlyRevenue]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Stored Procedure สำหรับคำนวณรายได้และมัดจำ
CREATE PROCEDURE [dbo].[sp_CalculateMonthlyRevenue]
    @Year INT,
    @Month INT
AS
BEGIN
    DECLARE @StartDate DATETIME = DATEFROMPARTS(@Year, @Month, 1)
    DECLARE @EndDate DATETIME = DATEADD(DAY, -1, DATEADD(MONTH, 1, @StartDate))
    SET @EndDate = DATEADD(SECOND, 86399, @EndDate) -- 23:59:59

    -- รายได้รวมจากค่าห้องพัก
    SELECT
        ISNULL(SUM(RA.Price * R.StayDays), 0) as TotalRevenue
    FROM [Reservation] R
    INNER JOIN Reservation_Accommodation RA ON RA.Reservation_ID = R.ID
    WHERE R.CheckinDate >= @StartDate AND R.CheckoutDate <= @EndDate
    AND R.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')

    -- ยอดเงินมัดจำทั้งหมด
    SELECT
        ISNULL(SUM(R.Deposit), 0) as TotalDeposit
    FROM [Reservation] R
    WHERE R.CheckinDate >= @StartDate AND R.CheckoutDate <= @EndDate
    AND R.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')
END
GO
/****** Object:  StoredProcedure [dbo].[sp_GetAccommodationRevenueReport]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Stored Procedure สำหรับรายงานห้องพักแบบละเอียด
CREATE PROCEDURE [dbo].[sp_GetAccommodationRevenueReport]
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    -- รายได้แยกตามประเภทห้องพัก
    SELECT
        A.AccomName AS 'ประเภทที่พัก',
        SUM(R.StayDays) AS 'จำนวนคืน',
        SUM(RA.Amount) AS 'จำนวนผู้พัก',
        SUM(RA.Price * R.StayDays) AS 'รายได้',
        COUNT(DISTINCT R.ID) AS 'จำนวนการจอง'
    FROM [Reservation] R
    INNER JOIN Reservation_Accommodation RA ON RA.Reservation_ID = R.ID
    INNER JOIN Accommodation A ON RA.Accommodation_ID = A.ID
    WHERE R.CheckinDate >= @StartDate AND R.CheckoutDate <= @EndDate
    AND R.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')
    GROUP BY A.ID, A.AccomName
    ORDER BY SUM(RA.Price * R.StayDays) DESC
END
GO
/****** Object:  StoredProcedure [dbo].[sp_GetReservationDetails]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Stored Procedure สำหรับดึงข้อมูลการจองแบบละเอียด
CREATE PROCEDURE [dbo].[sp_GetReservationDetails]
    @Year INT,
    @Month INT
AS
BEGIN
    DECLARE @StartDate DATETIME = DATEFROMPARTS(@Year, @Month, 1)
    DECLARE @EndDate DATETIME = DATEADD(DAY, -1, DATEADD(MONTH, 1, @StartDate))

    SELECT
        R.ID,
        R.CheckinDate,
        R.CheckoutDate,
        R.TotalPrice,
        R.Deposit,
        R.Status,
        C.Name,
        C.NickName,
        C.MobilePhone,
        RA.Accommodation_ID,
        RA.Amount as PeopleStay,
        A.AccomName,
        R.StayDays,
        RA.Price as PricePerNight
    FROM Reservation R
    INNER JOIN Customer C ON R.Customer_MobilePhone = C.MobilePhone
    INNER JOIN Reservation_Accommodation RA ON R.ID = RA.Reservation_ID
    INNER JOIN Accommodation A ON RA.Accommodation_ID = A.ID
    WHERE
        (R.CheckinDate <= @EndDate AND R.CheckoutDate >= @StartDate)
        AND R.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')
    ORDER BY R.CheckinDate, A.AccomName
END
GO
/****** Object:  StoredProcedure [dbo].[sp_VerifyRevenueCalculation]    Script Date: 10/29/2025 3:16:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Stored Procedure สำหรับตรวจสอบความถูกต้องของยอดเงิน
CREATE PROCEDURE [dbo].[sp_VerifyRevenueCalculation]
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    -- รายได้รวมจากค่าห้องพัก
    SELECT
        ISNULL(SUM(RA.Price * R.StayDays), 0) as TotalRevenue
    FROM [Reservation] R
    RIGHT JOIN Reservation_Accommodation RA ON RA.Reservation_ID = R.ID
    INNER JOIN Accommodation A ON RA.Accommodation_ID = A.ID
    WHERE R.CheckinDate >= @StartDate AND R.CheckoutDate <= @EndDate
    AND R.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')

    -- ยอดมัดจำทั้งหมด
    SELECT
        ISNULL(SUM(R.Deposit), 0) as TotalDeposit
    FROM [Reservation] R
    WHERE R.CheckinDate >= @StartDate AND R.CheckoutDate <= @EndDate
    AND R.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')

    -- ยอดรับมาแล้ว
    SELECT
        ISNULL(SUM(R.Deposit), 0) as TotalReceived
    FROM [Reservation] R
    WHERE R.CheckinDate >= @StartDate AND R.CheckoutDate <= @EndDate
    AND R.Status IN (N'ยืนยันแล้ว', N'เข้าพักแล้ว', N'เสร็จสิ้น')
    AND R.Deposit > 0
END
GO
USE [master]
GO
ALTER DATABASE [Taketime] SET  READ_WRITE
GO
