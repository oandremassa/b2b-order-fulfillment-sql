# Entity-relationship diagram

```mermaid
erDiagram
    CUSTOMER ||--o{ SALES_ORDER : places
    WAREHOUSE ||--o{ SALES_ORDER : fulfills
    SALES_ORDER ||--|{ SALES_ORDER_ITEM : contains
    PRODUCT_CATEGORY ||--o{ PRODUCT : classifies
    PRODUCT ||--o{ SALES_ORDER_ITEM : ordered_as
    SALES_ORDER ||--o| SHIPMENT : has
    SALES_ORDER_ITEM ||--o{ PRODUCT_RETURN : may_generate
    PRODUCT ||--o{ STOCK_MOVEMENT : changes
    WAREHOUSE ||--o{ STOCK_MOVEMENT : records
    PRODUCT ||--o{ STOCK_BALANCE : holds
    WAREHOUSE ||--o{ STOCK_BALANCE : holds
    DATA_QUALITY_RUN ||--|{ DATA_QUALITY_RESULT : contains

    CUSTOMER {
        int CustomerID PK
        varchar CustomerNumber UK
        nvarchar CustomerName
        varchar CustomerType
        varchar Industry
        varchar Email UK
        char CountryCode
        nvarchar City
        date RegistrationDate
        bit IsActive
    }

    PRODUCT_CATEGORY {
        int ProductCategoryID PK
        nvarchar CategoryName UK
        nvarchar Description
        bit IsActive
    }

    PRODUCT {
        int ProductID PK
        int ProductCategoryID FK
        varchar SKU UK
        nvarchar ProductName
        decimal StandardCost
        decimal ListPrice
        int ReorderLevel
        bit IsActive
    }

    WAREHOUSE {
        int WarehouseID PK
        varchar WarehouseCode UK
        nvarchar WarehouseName
        nvarchar City
        char CountryCode
        bit IsActive
    }

    SALES_ORDER {
        bigint OrderID PK
        varchar OrderNumber UK
        int CustomerID FK
        int WarehouseID FK
        date OrderDate
        date RequiredDeliveryDate
        varchar OrderStatus
        varchar SalesChannel
        smallint PaymentTermsDays
        nvarchar CancellationReason
    }

    SALES_ORDER_ITEM {
        bigint OrderItemID PK
        bigint OrderID FK
        smallint LineNumber
        int ProductID FK
        int Quantity
        decimal UnitPrice
        decimal DiscountRate
        decimal UnitCost
        decimal LineNetAmount
    }

    SHIPMENT {
        bigint ShipmentID PK
        bigint OrderID FK_UK
        varchar ShipmentNumber UK
        varchar ShipmentStatus
        date ShippedDate
        date DeliveredDate
        varchar Carrier
        varchar TrackingNumber
        decimal ShippingCost
    }

    PRODUCT_RETURN {
        bigint ReturnID PK
        bigint OrderItemID FK
        date ReturnDate
        int ReturnQuantity
        varchar ReturnReason
        varchar ReturnStatus
        decimal RefundAmount
    }

    STOCK_MOVEMENT {
        bigint StockMovementID PK
        int ProductID FK
        int WarehouseID FK
        datetime MovementDate
        varchar MovementType
        int QuantityChange
        varchar ReferenceType
        bigint ReferenceID
    }

    STOCK_BALANCE {
        int ProductID PK_FK
        int WarehouseID PK_FK
        int QuantityOnHand
        datetime LastUpdated
    }

    DATA_QUALITY_RUN {
        bigint RunID PK
        datetime StartedAt
        datetime CompletedAt
        varchar OverallStatus
        int ChecksPassed
        int ChecksFailed
    }

    DATA_QUALITY_RESULT {
        bigint ResultID PK
        bigint RunID FK
        nvarchar CheckName
        varchar Severity
        bigint FailedRowCount
        varchar CheckStatus
    }
```

## Relationship notes

- One customer can place many orders.
- Each order is assigned to one fulfillment warehouse.
- An order contains one or more order lines.
- Each fulfilled order has at most one shipment in the current project scope.
- A single order line can have zero or more return records.
- Inventory is tracked by product and warehouse through movements and a current balance.
