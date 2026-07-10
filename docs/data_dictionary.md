# Data dictionary

## `sales.Customer`

| Column | Type | Description |
|---|---|---|
| CustomerID | int | Surrogate primary key. |
| CustomerNumber | varchar(12) | Stable business identifier. |
| CustomerName | nvarchar(150) | Fictional company name. |
| CustomerType | varchar(20) | SMB, MidMarket, or Enterprise. |
| Industry | varchar(50) | Customer industry group. |
| Email | varchar(200) | Unique synthetic contact address. |
| CountryCode | char(2) | ISO-style country code. |
| City | nvarchar(100) | Main customer city. |
| RegistrationDate | date | Date customer entered the system. |
| IsActive | bit | Active-record flag. |
| CreatedAt | datetime2(0) | Record creation timestamp. |

## `inventory.ProductCategory`

| Column | Type | Description |
|---|---|---|
| ProductCategoryID | int | Surrogate primary key. |
| CategoryName | nvarchar(100) | Unique category name. |
| Description | nvarchar(250) | Business description. |
| IsActive | bit | Active-record flag. |
| CreatedAt | datetime2(0) | Record creation timestamp. |

## `inventory.Product`

| Column | Type | Description |
|---|---|---|
| ProductID | int | Surrogate primary key. |
| ProductCategoryID | int | Foreign key to product category. |
| SKU | varchar(20) | Unique stock-keeping unit. |
| ProductName | nvarchar(150) | Product description. |
| StandardCost | decimal(12,2) | Internal unit cost. |
| ListPrice | decimal(12,2) | Standard selling price. |
| ReorderLevel | int | Threshold used by the inventory-status view. |
| IsActive | bit | Active-record flag. |
| CreatedAt | datetime2(0) | Record creation timestamp. |

## `inventory.Warehouse`

| Column | Type | Description |
|---|---|---|
| WarehouseID | int | Surrogate primary key. |
| WarehouseCode | varchar(10) | Unique warehouse code. |
| WarehouseName | nvarchar(100) | Warehouse display name. |
| City | nvarchar(100) | Warehouse city. |
| CountryCode | char(2) | Country code. |
| IsActive | bit | Active-record flag. |
| CreatedAt | datetime2(0) | Record creation timestamp. |

## `sales.SalesOrder`

| Column | Type | Description |
|---|---|---|
| OrderID | bigint | Surrogate primary key. |
| OrderNumber | varchar(20) | Unique business identifier. |
| CustomerID | int | Customer foreign key. |
| WarehouseID | int | Fulfillment warehouse foreign key. |
| OrderDate | date | Date order was placed. |
| RequiredDeliveryDate | date | Customer-requested delivery deadline. |
| OrderStatus | varchar(20) | Operational order status. |
| SalesChannel | varchar(20) | Online, SalesRep, or Partner. |
| PaymentTermsDays | smallint | Payment term in days. |
| CancellationReason | nvarchar(150) | Reason recorded for cancellation. |
| CreatedAt | datetime2(0) | Record creation timestamp. |

## `sales.SalesOrderItem`

| Column | Type | Description |
|---|---|---|
| OrderItemID | bigint | Surrogate primary key. |
| OrderID | bigint | Order header foreign key. |
| LineNumber | smallint | Sequential line within an order. |
| ProductID | int | Product foreign key. |
| Quantity | int | Ordered units. |
| UnitPrice | decimal(12,2) | Selling price before discount. |
| DiscountRate | decimal(5,4) | Fractional discount, for example 0.0500. |
| UnitCost | decimal(12,2) | Cost captured at order time. |
| LineGrossAmount | computed | Quantity multiplied by unit price. |
| LineNetAmount | computed | Gross amount after discount. |
| LineCostAmount | computed | Quantity multiplied by unit cost. |
| CreatedAt | datetime2(0) | Record creation timestamp. |

## `sales.Shipment`

| Column | Type | Description |
|---|---|---|
| ShipmentID | bigint | Surrogate primary key. |
| OrderID | bigint | Unique foreign key to order. |
| ShipmentNumber | varchar(20) | Unique shipment identifier. |
| ShipmentStatus | varchar(20) | Preparing, InTransit, Delivered, or Cancelled. |
| ShippedDate | date | Dispatch date. |
| DeliveredDate | date | Delivery date where applicable. |
| Carrier | varchar(50) | Fictional logistics provider. |
| TrackingNumber | varchar(30) | Synthetic tracking code. |
| ShippingCost | decimal(12,2) | Cost of shipment. |
| CreatedAt | datetime2(0) | Record creation timestamp. |

## `sales.ProductReturn`

| Column | Type | Description |
|---|---|---|
| ReturnID | bigint | Surrogate primary key. |
| OrderItemID | bigint | Returned order line. |
| ReturnDate | date | Return request date. |
| ReturnQuantity | int | Number of units returned. |
| ReturnReason | varchar(30) | Business reason category. |
| ReturnStatus | varchar(20) | Requested, Approved, Received, or Rejected. |
| RefundAmount | decimal(12,2) | Approved refund value. |
| CreatedAt | datetime2(0) | Record creation timestamp. |

## `inventory.StockMovement`

| Column | Type | Description |
|---|---|---|
| StockMovementID | bigint | Surrogate primary key. |
| ProductID | int | Product foreign key. |
| WarehouseID | int | Warehouse foreign key. |
| MovementDate | datetime2(0) | Operational movement timestamp. |
| MovementType | varchar(20) | Opening, Receipt, Sale, Return, or Adjustment. |
| QuantityChange | int | Signed quantity change. |
| ReferenceType | varchar(20) | Source object type. |
| ReferenceID | bigint | Optional source record identifier. |
| Notes | nvarchar(200) | Human-readable explanation. |
| CreatedAt | datetime2(0) | Record creation timestamp. |

## `inventory.StockBalance`

| Column | Type | Description |
|---|---|---|
| ProductID | int | Product key and first part of composite PK. |
| WarehouseID | int | Warehouse key and second part of composite PK. |
| QuantityOnHand | int | Current available quantity. |
| LastUpdated | datetime2(0) | Last balance refresh timestamp. |

## Audit tables

`audit.DataQualityRun` stores one record per execution. `audit.DataQualityResult` stores the outcome and failed-row count for each rule executed in that run.
