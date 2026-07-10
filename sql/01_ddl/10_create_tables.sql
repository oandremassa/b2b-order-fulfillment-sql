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

CREATE TABLE sales.Customer
(
    CustomerID         int IDENTITY(1,1) NOT NULL,
    CustomerNumber     varchar(12) NOT NULL,
    CustomerName       nvarchar(150) NOT NULL,
    CustomerType       varchar(20) NOT NULL,
    Industry           varchar(50) NOT NULL,
    Email              varchar(200) NOT NULL,
    CountryCode        char(2) NOT NULL,
    City               nvarchar(100) NOT NULL,
    RegistrationDate   date NOT NULL,
    IsActive            bit NOT NULL CONSTRAINT DF_Customer_IsActive DEFAULT (1),
    CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_Customer_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Customer PRIMARY KEY CLUSTERED (CustomerID)
);
GO

CREATE TABLE inventory.ProductCategory
(
    ProductCategoryID  int IDENTITY(1,1) NOT NULL,
    CategoryName       nvarchar(100) NOT NULL,
    Description        nvarchar(250) NULL,
    IsActive            bit NOT NULL CONSTRAINT DF_ProductCategory_IsActive DEFAULT (1),
    CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_ProductCategory_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_ProductCategory PRIMARY KEY CLUSTERED (ProductCategoryID)
);
GO

CREATE TABLE inventory.Product
(
    ProductID           int IDENTITY(1,1) NOT NULL,
    ProductCategoryID   int NOT NULL,
    SKU                 varchar(20) NOT NULL,
    ProductName         nvarchar(150) NOT NULL,
    StandardCost        decimal(12,2) NOT NULL,
    ListPrice           decimal(12,2) NOT NULL,
    ReorderLevel        int NOT NULL,
    IsActive            bit NOT NULL CONSTRAINT DF_Product_IsActive DEFAULT (1),
    CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_Product_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Product PRIMARY KEY CLUSTERED (ProductID)
);
GO

CREATE TABLE inventory.Warehouse
(
    WarehouseID         int IDENTITY(1,1) NOT NULL,
    WarehouseCode       varchar(10) NOT NULL,
    WarehouseName       nvarchar(100) NOT NULL,
    City                nvarchar(100) NOT NULL,
    CountryCode         char(2) NOT NULL,
    IsActive            bit NOT NULL CONSTRAINT DF_Warehouse_IsActive DEFAULT (1),
    CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_Warehouse_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Warehouse PRIMARY KEY CLUSTERED (WarehouseID)
);
GO

CREATE TABLE sales.SalesOrder
(
    OrderID               bigint IDENTITY(1,1) NOT NULL,
    OrderNumber           varchar(20) NOT NULL,
    CustomerID            int NOT NULL,
    WarehouseID           int NOT NULL,
    OrderDate              date NOT NULL,
    RequiredDeliveryDate   date NOT NULL,
    OrderStatus            varchar(20) NOT NULL,
    SalesChannel           varchar(20) NOT NULL,
    PaymentTermsDays       smallint NOT NULL,
    CancellationReason     nvarchar(150) NULL,
    CreatedAt              datetime2(0) NOT NULL CONSTRAINT DF_SalesOrder_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_SalesOrder PRIMARY KEY CLUSTERED (OrderID)
);
GO

CREATE TABLE sales.SalesOrderItem
(
    OrderItemID        bigint IDENTITY(1,1) NOT NULL,
    OrderID            bigint NOT NULL,
    LineNumber         smallint NOT NULL,
    ProductID          int NOT NULL,
    Quantity           int NOT NULL,
    UnitPrice          decimal(12,2) NOT NULL,
    DiscountRate       decimal(5,4) NOT NULL CONSTRAINT DF_SalesOrderItem_DiscountRate DEFAULT (0),
    UnitCost           decimal(12,2) NOT NULL,
    LineGrossAmount AS CAST(Quantity * UnitPrice AS decimal(18,2)) PERSISTED,
    LineNetAmount AS CAST(Quantity * UnitPrice * (1 - DiscountRate) AS decimal(18,2)) PERSISTED,
    LineCostAmount AS CAST(Quantity * UnitCost AS decimal(18,2)) PERSISTED,
    CreatedAt          datetime2(0) NOT NULL CONSTRAINT DF_SalesOrderItem_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_SalesOrderItem PRIMARY KEY CLUSTERED (OrderItemID)
);
GO

CREATE TABLE sales.Shipment
(
    ShipmentID          bigint IDENTITY(1,1) NOT NULL,
    OrderID             bigint NOT NULL,
    ShipmentNumber      varchar(20) NOT NULL,
    ShipmentStatus      varchar(20) NOT NULL,
    ShippedDate         date NULL,
    DeliveredDate       date NULL,
    Carrier             varchar(50) NOT NULL,
    TrackingNumber      varchar(30) NULL,
    ShippingCost        decimal(12,2) NOT NULL,
    CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_Shipment_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Shipment PRIMARY KEY CLUSTERED (ShipmentID)
);
GO

CREATE TABLE sales.ProductReturn
(
    ReturnID            bigint IDENTITY(1,1) NOT NULL,
    OrderItemID         bigint NOT NULL,
    ReturnDate          date NOT NULL,
    ReturnQuantity      int NOT NULL,
    ReturnReason        varchar(30) NOT NULL,
    ReturnStatus        varchar(20) NOT NULL,
    RefundAmount        decimal(12,2) NOT NULL,
    CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_ProductReturn_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_ProductReturn PRIMARY KEY CLUSTERED (ReturnID)
);
GO

CREATE TABLE inventory.StockMovement
(
    StockMovementID     bigint IDENTITY(1,1) NOT NULL,
    ProductID           int NOT NULL,
    WarehouseID         int NOT NULL,
    MovementDate        datetime2(0) NOT NULL,
    MovementType        varchar(20) NOT NULL,
    QuantityChange      int NOT NULL,
    ReferenceType       varchar(20) NULL,
    ReferenceID         bigint NULL,
    Notes               nvarchar(200) NULL,
    CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_StockMovement_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_StockMovement PRIMARY KEY CLUSTERED (StockMovementID)
);
GO

CREATE TABLE inventory.StockBalance
(
    ProductID           int NOT NULL,
    WarehouseID         int NOT NULL,
    QuantityOnHand      int NOT NULL,
    LastUpdated         datetime2(0) NOT NULL CONSTRAINT DF_StockBalance_LastUpdated DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_StockBalance PRIMARY KEY CLUSTERED (ProductID, WarehouseID)
);
GO

CREATE TABLE audit.DataQualityRun
(
    RunID               bigint IDENTITY(1,1) NOT NULL,
    StartedAt           datetime2(0) NOT NULL,
    CompletedAt         datetime2(0) NULL,
    OverallStatus       varchar(10) NULL,
    ChecksPassed        int NULL,
    ChecksFailed        int NULL,
    CONSTRAINT PK_DataQualityRun PRIMARY KEY CLUSTERED (RunID)
);
GO

CREATE TABLE audit.DataQualityResult
(
    ResultID            bigint IDENTITY(1,1) NOT NULL,
    RunID               bigint NOT NULL,
    CheckName           nvarchar(150) NOT NULL,
    Severity            varchar(10) NOT NULL,
    FailedRowCount      bigint NOT NULL,
    CheckStatus         varchar(10) NOT NULL,
    Details             nvarchar(500) NULL,
    CheckedAt           datetime2(0) NOT NULL CONSTRAINT DF_DataQualityResult_CheckedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_DataQualityResult PRIMARY KEY CLUSTERED (ResultID)
);
GO

PRINT 'Tables created.';
GO
