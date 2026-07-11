SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

USE [$(DatabaseName)];
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'mart')
    EXEC('CREATE SCHEMA mart AUTHORIZATION dbo;');
GO

DROP PROCEDURE IF EXISTS mart.usp_ValidateReportingMart;
DROP PROCEDURE IF EXISTS mart.usp_LoadReportingMart;
GO

DROP TABLE IF EXISTS mart.FactInventorySnapshot;
DROP TABLE IF EXISTS mart.FactReturn;
DROP TABLE IF EXISTS mart.FactSalesLine;
DROP TABLE IF EXISTS mart.FactOrder;
DROP TABLE IF EXISTS mart.DimSalesChannel;
DROP TABLE IF EXISTS mart.DimWarehouse;
DROP TABLE IF EXISTS mart.DimProduct;
DROP TABLE IF EXISTS mart.DimCustomer;
DROP TABLE IF EXISTS mart.DimDate;
GO

CREATE TABLE mart.DimDate
(
    DateKey int NOT NULL,
    FullDate date NOT NULL,
    CalendarYear smallint NOT NULL,
    CalendarQuarter tinyint NOT NULL,
    QuarterLabel char(2) NOT NULL,
    MonthNumber tinyint NOT NULL,
    MonthName varchar(12) NOT NULL,
    YearMonthNumber int NOT NULL,
    YearMonthLabel char(7) NOT NULL,
    DayOfMonth tinyint NOT NULL,
    DayName varchar(12) NOT NULL,
    IsWeekend bit NOT NULL,
    CONSTRAINT PK_DimDate PRIMARY KEY CLUSTERED (DateKey),
    CONSTRAINT UQ_DimDate_FullDate UNIQUE (FullDate)
);
GO

CREATE TABLE mart.DimCustomer
(
    CustomerKey int IDENTITY(1,1) NOT NULL,
    SourceCustomerID int NOT NULL,
    CustomerNumber varchar(12) NOT NULL,
    CustomerName nvarchar(150) NOT NULL,
    CustomerType varchar(20) NOT NULL,
    Industry varchar(50) NOT NULL,
    CountryCode char(2) NOT NULL,
    City nvarchar(100) NOT NULL,
    RegistrationDate date NOT NULL,
    IsActive bit NOT NULL,
    CONSTRAINT PK_DimCustomer PRIMARY KEY CLUSTERED (CustomerKey),
    CONSTRAINT UQ_DimCustomer_SourceCustomerID UNIQUE (SourceCustomerID),
    CONSTRAINT UQ_DimCustomer_CustomerNumber UNIQUE (CustomerNumber)
);
GO

CREATE TABLE mart.DimProduct
(
    ProductKey int IDENTITY(1,1) NOT NULL,
    SourceProductID int NOT NULL,
    SKU varchar(20) NOT NULL,
    ProductName nvarchar(150) NOT NULL,
    CategoryName nvarchar(100) NOT NULL,
    StandardCost decimal(12,2) NOT NULL,
    ListPrice decimal(12,2) NOT NULL,
    ReorderLevel int NOT NULL,
    IsActive bit NOT NULL,
    CONSTRAINT PK_DimProduct PRIMARY KEY CLUSTERED (ProductKey),
    CONSTRAINT UQ_DimProduct_SourceProductID UNIQUE (SourceProductID),
    CONSTRAINT UQ_DimProduct_SKU UNIQUE (SKU)
);
GO

CREATE TABLE mart.DimWarehouse
(
    WarehouseKey int IDENTITY(1,1) NOT NULL,
    SourceWarehouseID int NOT NULL,
    WarehouseCode varchar(10) NOT NULL,
    WarehouseName nvarchar(100) NOT NULL,
    City nvarchar(100) NOT NULL,
    CountryCode char(2) NOT NULL,
    IsActive bit NOT NULL,
    CONSTRAINT PK_DimWarehouse PRIMARY KEY CLUSTERED (WarehouseKey),
    CONSTRAINT UQ_DimWarehouse_SourceWarehouseID UNIQUE (SourceWarehouseID),
    CONSTRAINT UQ_DimWarehouse_WarehouseCode UNIQUE (WarehouseCode)
);
GO

CREATE TABLE mart.DimSalesChannel
(
    SalesChannelKey tinyint NOT NULL,
    SalesChannel varchar(20) NOT NULL,
    CONSTRAINT PK_DimSalesChannel PRIMARY KEY CLUSTERED (SalesChannelKey),
    CONSTRAINT UQ_DimSalesChannel_Name UNIQUE (SalesChannel)
);
GO

CREATE TABLE mart.FactOrder
(
    OrderKey bigint NOT NULL,
    OrderNumber varchar(20) NOT NULL,
    OrderDateKey int NOT NULL,
    RequiredDeliveryDateKey int NOT NULL,
    ShippedDateKey int NULL,
    DeliveredDateKey int NULL,
    CustomerKey int NOT NULL,
    WarehouseKey int NOT NULL,
    SalesChannelKey tinyint NOT NULL,
    OrderStatus varchar(20) NOT NULL,
    ShipmentStatus varchar(20) NULL,
    Carrier varchar(50) NULL,
    PaymentTermsDays smallint NOT NULL,
    LineCount bigint NOT NULL,
    TotalQuantity int NOT NULL,
    GrossOrderValue decimal(18,2) NOT NULL,
    NetOrderValue decimal(18,2) NOT NULL,
    CostAmount decimal(18,2) NOT NULL,
    GrossMarginAmount decimal(18,2) NOT NULL,
    ShippingCost decimal(12,2) NULL,
    DeliveryDays int NULL,
    IsOnTimeDelivery bit NULL,
    CONSTRAINT PK_FactOrder PRIMARY KEY CLUSTERED (OrderKey),
    CONSTRAINT FK_FactOrder_OrderDate FOREIGN KEY (OrderDateKey) REFERENCES mart.DimDate (DateKey),
    CONSTRAINT FK_FactOrder_RequiredDate FOREIGN KEY (RequiredDeliveryDateKey) REFERENCES mart.DimDate (DateKey),
    CONSTRAINT FK_FactOrder_ShippedDate FOREIGN KEY (ShippedDateKey) REFERENCES mart.DimDate (DateKey),
    CONSTRAINT FK_FactOrder_DeliveredDate FOREIGN KEY (DeliveredDateKey) REFERENCES mart.DimDate (DateKey),
    CONSTRAINT FK_FactOrder_Customer FOREIGN KEY (CustomerKey) REFERENCES mart.DimCustomer (CustomerKey),
    CONSTRAINT FK_FactOrder_Warehouse FOREIGN KEY (WarehouseKey) REFERENCES mart.DimWarehouse (WarehouseKey),
    CONSTRAINT FK_FactOrder_SalesChannel FOREIGN KEY (SalesChannelKey) REFERENCES mart.DimSalesChannel (SalesChannelKey)
);
GO

CREATE TABLE mart.FactSalesLine
(
    OrderItemKey bigint NOT NULL,
    OrderKey bigint NOT NULL,
    OrderNumber varchar(20) NOT NULL,
    LineNumber smallint NOT NULL,
    OrderDateKey int NOT NULL,
    CustomerKey int NOT NULL,
    ProductKey int NOT NULL,
    WarehouseKey int NOT NULL,
    SalesChannelKey tinyint NOT NULL,
    OrderStatus varchar(20) NOT NULL,
    Quantity int NOT NULL,
    UnitPrice decimal(12,2) NOT NULL,
    DiscountRate decimal(5,4) NOT NULL,
    UnitCost decimal(12,2) NOT NULL,
    GrossSalesAmount decimal(18,2) NOT NULL,
    NetSalesAmount decimal(18,2) NOT NULL,
    CostAmount decimal(18,2) NOT NULL,
    GrossMarginAmount decimal(18,2) NOT NULL,
    IsCompleted bit NOT NULL,
    CONSTRAINT PK_FactSalesLine PRIMARY KEY CLUSTERED (OrderItemKey),
    CONSTRAINT FK_FactSalesLine_OrderDate FOREIGN KEY (OrderDateKey) REFERENCES mart.DimDate (DateKey),
    CONSTRAINT FK_FactSalesLine_Customer FOREIGN KEY (CustomerKey) REFERENCES mart.DimCustomer (CustomerKey),
    CONSTRAINT FK_FactSalesLine_Product FOREIGN KEY (ProductKey) REFERENCES mart.DimProduct (ProductKey),
    CONSTRAINT FK_FactSalesLine_Warehouse FOREIGN KEY (WarehouseKey) REFERENCES mart.DimWarehouse (WarehouseKey),
    CONSTRAINT FK_FactSalesLine_SalesChannel FOREIGN KEY (SalesChannelKey) REFERENCES mart.DimSalesChannel (SalesChannelKey)
);
GO

CREATE TABLE mart.FactReturn
(
    ReturnKey bigint NOT NULL,
    OrderKey bigint NOT NULL,
    OrderItemKey bigint NOT NULL,
    ReturnDateKey int NOT NULL,
    OrderDateKey int NOT NULL,
    CustomerKey int NOT NULL,
    ProductKey int NOT NULL,
    WarehouseKey int NOT NULL,
    SalesChannelKey tinyint NOT NULL,
    ReturnStatus varchar(20) NOT NULL,
    ReturnReason varchar(30) NOT NULL,
    ReturnQuantity int NOT NULL,
    RefundAmount decimal(12,2) NOT NULL,
    IsAcceptedReturn bit NOT NULL,
    CONSTRAINT PK_FactReturn PRIMARY KEY CLUSTERED (ReturnKey),
    CONSTRAINT FK_FactReturn_ReturnDate FOREIGN KEY (ReturnDateKey) REFERENCES mart.DimDate (DateKey),
    CONSTRAINT FK_FactReturn_OrderDate FOREIGN KEY (OrderDateKey) REFERENCES mart.DimDate (DateKey),
    CONSTRAINT FK_FactReturn_Customer FOREIGN KEY (CustomerKey) REFERENCES mart.DimCustomer (CustomerKey),
    CONSTRAINT FK_FactReturn_Product FOREIGN KEY (ProductKey) REFERENCES mart.DimProduct (ProductKey),
    CONSTRAINT FK_FactReturn_Warehouse FOREIGN KEY (WarehouseKey) REFERENCES mart.DimWarehouse (WarehouseKey),
    CONSTRAINT FK_FactReturn_SalesChannel FOREIGN KEY (SalesChannelKey) REFERENCES mart.DimSalesChannel (SalesChannelKey)
);
GO

CREATE TABLE mart.FactInventorySnapshot
(
    SnapshotDateKey int NOT NULL,
    ProductKey int NOT NULL,
    WarehouseKey int NOT NULL,
    QuantityOnHand int NOT NULL,
    ReorderLevel int NOT NULL,
    UnitsAboveReorderLevel int NOT NULL,
    StockStatus varchar(20) NOT NULL,
    CONSTRAINT PK_FactInventorySnapshot PRIMARY KEY CLUSTERED (SnapshotDateKey, ProductKey, WarehouseKey),
    CONSTRAINT FK_FactInventorySnapshot_Date FOREIGN KEY (SnapshotDateKey) REFERENCES mart.DimDate (DateKey),
    CONSTRAINT FK_FactInventorySnapshot_Product FOREIGN KEY (ProductKey) REFERENCES mart.DimProduct (ProductKey),
    CONSTRAINT FK_FactInventorySnapshot_Warehouse FOREIGN KEY (WarehouseKey) REFERENCES mart.DimWarehouse (WarehouseKey)
);
GO

CREATE INDEX IX_FactOrder_OrderDate ON mart.FactOrder (OrderDateKey) INCLUDE (CustomerKey, WarehouseKey, SalesChannelKey, OrderStatus, NetOrderValue, GrossMarginAmount);
CREATE INDEX IX_FactOrder_Customer ON mart.FactOrder (CustomerKey, OrderDateKey);
CREATE INDEX IX_FactOrder_Warehouse ON mart.FactOrder (WarehouseKey, OrderDateKey);
CREATE INDEX IX_FactSalesLine_OrderDate ON mart.FactSalesLine (OrderDateKey) INCLUDE (CustomerKey, ProductKey, WarehouseKey, SalesChannelKey, IsCompleted, NetSalesAmount, GrossMarginAmount);
CREATE INDEX IX_FactSalesLine_Product ON mart.FactSalesLine (ProductKey, OrderDateKey);
CREATE INDEX IX_FactReturn_ReturnDate ON mart.FactReturn (ReturnDateKey) INCLUDE (ProductKey, CustomerKey, ReturnQuantity, RefundAmount, IsAcceptedReturn);
CREATE INDEX IX_FactInventorySnapshot_Status ON mart.FactInventorySnapshot (StockStatus, WarehouseKey) INCLUDE (ProductKey, QuantityOnHand, ReorderLevel);
GO

PRINT 'Reporting mart tables created.';
GO
