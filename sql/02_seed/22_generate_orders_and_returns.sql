USE [$(DatabaseName)];
GO
SET NOCOUNT ON;

/*
Synthetic demand design
-----------------------
- Customers 1-320 receive at least one order.
- Customers 1-240 form the repeat-purchase base.
- Repeat demand is weighted toward enterprise and mid-market accounts.
- Sales channel depends on customer type instead of being evenly distributed.
- Warehouse assignment follows a simple geographic rule.
*/
;WITH
E1(N) AS
(
    SELECT 1
    FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) AS D(N)
),
E2(N) AS (SELECT 1 FROM E1 A CROSS JOIN E1 B),
E4(N) AS (SELECT 1 FROM E2 A CROSS JOIN E2 B),
Numbers AS
(
    SELECT TOP (5000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM E4
),
OrderSeeds AS
(
    SELECT
        N,
        ABS(CONVERT(bigint, CHECKSUM(CONCAT('order-', N)))) AS Seed,
        ABS(CONVERT(bigint, CHECKSUM(CONCAT('customer-order-', N)))) AS CustomerSeed,
        ABS(CONVERT(bigint, CHECKSUM(CONCAT('channel-order-', N)))) AS ChannelSeed,
        DATEADD(
            DAY,
            CONVERT(int, ABS(CONVERT(bigint, CHECKSUM(CONCAT('order-date-', N)))) % 731),
            CONVERT(date, '2024-01-01')
        ) AS OrderDate
    FROM Numbers
),
CustomerAssignments AS
(
    SELECT
        S.*,
        CASE
            WHEN S.N <= 320 THEN S.N
            WHEN S.CustomerSeed % 100 < 35
                THEN 1 + CONVERT(int, (S.CustomerSeed / 101) % 40)
            WHEN S.CustomerSeed % 100 < 75
                THEN 41 + CONVERT(int, (S.CustomerSeed / 101) % 100)
            ELSE 141 + CONVERT(int, (S.CustomerSeed / 101) % 100)
        END AS CustomerOrdinal
    FROM OrderSeeds S
),
OrderAttributes AS
(
    SELECT
        A.*,
        C.CustomerID,
        C.CustomerType,
        C.City,
        CASE
            WHEN C.City IN (N'Hamburg', N'Amsterdam') THEN 'HAM'
            WHEN C.City IN (N'Berlin', N'Leipzig') THEN 'LEJ'
            ELSE 'MHM'
        END AS WarehouseCode,
        CASE
            WHEN A.OrderDate >= '2025-12-24' AND A.Seed % 100 < 35 THEN 'Pending'
            WHEN A.OrderDate >= '2025-12-18' AND A.Seed % 100 < 60 THEN 'Processing'
            WHEN A.OrderDate >= '2025-12-12' AND A.Seed % 100 < 75 THEN 'Shipped'
            WHEN A.N > 320 AND A.Seed % 100 < 5 THEN 'Cancelled'
            ELSE 'Completed'
        END AS OrderStatus,
        CASE
            WHEN C.CustomerType = 'Enterprise' THEN
                CASE
                    WHEN A.ChannelSeed % 100 < 55 THEN 'SalesRep'
                    WHEN A.ChannelSeed % 100 < 90 THEN 'Partner'
                    ELSE 'Online'
                END
            WHEN C.CustomerType = 'MidMarket' THEN
                CASE
                    WHEN A.ChannelSeed % 100 < 45 THEN 'SalesRep'
                    WHEN A.ChannelSeed % 100 < 80 THEN 'Online'
                    ELSE 'Partner'
                END
            ELSE
                CASE
                    WHEN A.ChannelSeed % 100 < 60 THEN 'Online'
                    WHEN A.ChannelSeed % 100 < 85 THEN 'Partner'
                    ELSE 'SalesRep'
                END
        END AS SalesChannel
    FROM CustomerAssignments A
    JOIN sales.Customer C
      ON C.CustomerNumber = CONCAT(
          'C',
          RIGHT('000000' + CONVERT(varchar(6), A.CustomerOrdinal), 6)
      )
)
INSERT sales.SalesOrder
(
    OrderNumber,
    CustomerID,
    WarehouseID,
    OrderDate,
    RequiredDeliveryDate,
    OrderStatus,
    SalesChannel,
    PaymentTermsDays,
    CancellationReason
)
SELECT
    CONCAT('SO-', RIGHT('000000' + CONVERT(varchar(6), N), 6)),
    CustomerID,
    W.WarehouseID,
    OrderDate,
    DATEADD(DAY, 3 + CONVERT(int, (Seed / 11) % 8), OrderDate),
    OrderStatus,
    SalesChannel,
    CASE CustomerType
        WHEN 'Enterprise' THEN
            CASE Seed % 3 WHEN 0 THEN 30 WHEN 1 THEN 45 ELSE 60 END
        WHEN 'MidMarket' THEN
            CASE Seed % 3 WHEN 0 THEN 14 WHEN 1 THEN 30 ELSE 45 END
        ELSE
            CASE Seed % 3 WHEN 0 THEN 0 WHEN 1 THEN 14 ELSE 30 END
    END,
    CASE
        WHEN OrderStatus = 'Cancelled' THEN
            CASE Seed % 3
                WHEN 0 THEN N'Customer request'
                WHEN 1 THEN N'Payment not confirmed'
                ELSE N'Product unavailable'
            END
        ELSE NULL
    END
FROM OrderAttributes A
JOIN inventory.Warehouse W
  ON W.WarehouseCode = A.WarehouseCode;
GO

;WITH LineNumbers AS
(
    SELECT LineNumber
    FROM (VALUES (1),(2),(3),(4),(5)) AS L(LineNumber)
),
OrderLineSeeds AS
(
    SELECT
        O.OrderID,
        O.OrderNumber,
        O.SalesChannel,
        C.CustomerType,
        L.LineNumber,
        ABS(CONVERT(bigint, CHECKSUM(CONCAT('line-', O.OrderID, '-', L.LineNumber)))) AS LineSeed,
        ABS(CONVERT(bigint, CHECKSUM(CONCAT('product-order-', O.OrderID)))) AS ProductBaseSeed
    FROM sales.SalesOrder O
    JOIN sales.Customer C
      ON C.CustomerID = O.CustomerID
    CROSS JOIN LineNumbers L
    WHERE L.LineNumber <=
        CASE C.CustomerType
            WHEN 'Enterprise' THEN 3 + ABS(CONVERT(bigint, CHECKSUM(CONCAT('line-count-', O.OrderID)))) % 3
            WHEN 'MidMarket' THEN 2 + ABS(CONVERT(bigint, CHECKSUM(CONCAT('line-count-', O.OrderID)))) % 3
            ELSE 1 + ABS(CONVERT(bigint, CHECKSUM(CONCAT('line-count-', O.OrderID)))) % 3
        END
),
ProductAssignments AS
(
    SELECT
        S.*,
        CASE
            WHEN S.LineSeed % 100 < 45 THEN
                1 + CONVERT(int, (S.ProductBaseSeed + S.LineNumber * 3) % 15)
            WHEN S.LineSeed % 100 < 80 THEN
                16 + CONVERT(int, (S.ProductBaseSeed + S.LineNumber * 7) % 30)
            ELSE
                46 + CONVERT(int, (S.ProductBaseSeed + S.LineNumber * 11) % 45)
        END AS ProductOrdinal
    FROM OrderLineSeeds S
)
INSERT sales.SalesOrderItem
(
    OrderID,
    LineNumber,
    ProductID,
    Quantity,
    UnitPrice,
    DiscountRate,
    UnitCost
)
SELECT
    S.OrderID,
    S.LineNumber,
    P.ProductID,
    CASE S.CustomerType
        WHEN 'Enterprise' THEN 8 + CONVERT(int, (S.LineSeed / 5) % 23)
        WHEN 'MidMarket' THEN 4 + CONVERT(int, (S.LineSeed / 5) % 15)
        ELSE 1 + CONVERT(int, (S.LineSeed / 5) % 10)
    END,
    P.ListPrice,
    CASE S.SalesChannel
        WHEN 'Partner' THEN
            CASE WHEN S.LineSeed % 100 < 30 THEN 0.1500 ELSE 0.1000 END
        WHEN 'SalesRep' THEN
            CASE
                WHEN S.CustomerType = 'Enterprise' AND S.LineSeed % 100 < 50 THEN 0.1000
                WHEN S.CustomerType = 'MidMarket' AND S.LineSeed % 100 < 25 THEN 0.1000
                ELSE 0.0500
            END
        ELSE
            CASE WHEN S.LineSeed % 100 < 20 THEN 0.0500 ELSE 0.0000 END
    END,
    P.StandardCost
FROM ProductAssignments S
JOIN inventory.Product P
  ON P.SKU = CONCAT(
      'PRD-',
      RIGHT('0000' + CONVERT(varchar(4), S.ProductOrdinal), 4)
  );
GO

;WITH ShipmentSeeds AS
(
    SELECT
        O.OrderID,
        O.OrderStatus,
        O.OrderDate,
        O.RequiredDeliveryDate,
        ABS(CONVERT(bigint, CHECKSUM(CONCAT('shipment-', O.OrderID)))) AS Seed
    FROM sales.SalesOrder O
    WHERE O.OrderStatus IN ('Shipped', 'Completed')
),
ShipmentDates AS
(
    SELECT
        S.*,
        DATEADD(DAY, 1 + CONVERT(int, S.Seed % 4), S.OrderDate) AS CalculatedShippedDate
    FROM ShipmentSeeds S
)
INSERT sales.Shipment
(
    OrderID,
    ShipmentNumber,
    ShipmentStatus,
    ShippedDate,
    DeliveredDate,
    Carrier,
    TrackingNumber,
    ShippingCost
)
SELECT
    D.OrderID,
    CONCAT('SHP-', RIGHT('000000' + CONVERT(varchar(6), D.OrderID), 6)),
    CASE WHEN D.OrderStatus = 'Completed' THEN 'Delivered' ELSE 'InTransit' END,
    D.CalculatedShippedDate,
    CASE
        WHEN D.OrderStatus = 'Completed'
        THEN DATEADD(
            DAY,
            CASE
                WHEN D.Seed % 100 < 14 THEN 7 + CONVERT(int, D.Seed % 4)
                ELSE 1 + CONVERT(int, D.Seed % 5)
            END,
            D.CalculatedShippedDate
        )
        ELSE NULL
    END,
    CASE D.Seed % 4
        WHEN 0 THEN 'DHL'
        WHEN 1 THEN 'DPD'
        WHEN 2 THEN 'GLS'
        ELSE 'UPS'
    END,
    CONCAT('TRK', RIGHT('000000000' + CONVERT(varchar(9), D.OrderID), 9)),
    CAST(8.00 + (D.Seed % 3200) / 100.0 AS decimal(12,2))
FROM ShipmentDates D;
GO

;WITH ReturnCandidates AS
(
    SELECT
        OI.OrderItemID,
        OI.Quantity,
        OI.UnitPrice,
        OI.DiscountRate,
        PC.CategoryName,
        O.RequiredDeliveryDate,
        S.DeliveredDate,
        ABS(CONVERT(bigint, CHECKSUM(CONCAT('return-', OI.OrderItemID)))) AS Seed
    FROM sales.SalesOrderItem OI
    JOIN sales.SalesOrder O
      ON O.OrderID = OI.OrderID
    JOIN sales.Shipment S
      ON S.OrderID = O.OrderID
    JOIN inventory.Product P
      ON P.ProductID = OI.ProductID
    JOIN inventory.ProductCategory PC
      ON PC.ProductCategoryID = P.ProductCategoryID
    WHERE O.OrderStatus = 'Completed'
      AND S.DeliveredDate IS NOT NULL
      AND ABS(CONVERT(bigint, CHECKSUM(CONCAT('return-select-', OI.OrderItemID)))) % 100
          <
          CASE PC.CategoryName
              WHEN N'IT Accessories' THEN 6
              WHEN N'Networking' THEN 4
              WHEN N'Office Equipment' THEN 7
              WHEN N'Storage Solutions' THEN 5
              WHEN N'Safety Equipment' THEN 3
              ELSE 2
          END
          + CASE WHEN S.DeliveredDate > O.RequiredDeliveryDate THEN 3 ELSE 0 END
),
ReturnPrepared AS
(
    SELECT
        R.*,
        CASE
            WHEN R.Quantity = 1 THEN 1
            WHEN R.Seed % 100 < 85 THEN 1
            ELSE 1 + CONVERT(int, R.Seed % (CASE WHEN R.Quantity < 3 THEN R.Quantity ELSE 3 END))
        END AS ReturnQuantity,
        CASE
            WHEN R.DeliveredDate > R.RequiredDeliveryDate AND R.Seed % 100 < 50 THEN 'LateDelivery'
            WHEN R.Seed % 4 = 0 THEN 'Damaged'
            WHEN R.Seed % 4 = 1 THEN 'WrongItem'
            WHEN R.Seed % 4 = 2 THEN 'NotNeeded'
            ELSE 'QualityIssue'
        END AS ReturnReason,
        CASE
            WHEN R.Seed % 100 < 70 THEN 'Received'
            WHEN R.Seed % 100 < 85 THEN 'Approved'
            WHEN R.Seed % 100 < 95 THEN 'Requested'
            ELSE 'Rejected'
        END AS ReturnStatus
    FROM ReturnCandidates R
)
INSERT sales.ProductReturn
(
    OrderItemID,
    ReturnDate,
    ReturnQuantity,
    ReturnReason,
    ReturnStatus,
    RefundAmount
)
SELECT
    R.OrderItemID,
    DATEADD(DAY, 3 + CONVERT(int, R.Seed % 22), R.DeliveredDate),
    R.ReturnQuantity,
    R.ReturnReason,
    R.ReturnStatus,
    CASE
        WHEN R.ReturnStatus IN ('Approved', 'Received') THEN
            CAST(
                ROUND(R.ReturnQuantity * R.UnitPrice * (1 - R.DiscountRate), 2)
                AS decimal(12,2)
            )
        ELSE 0
    END
FROM ReturnPrepared R;
GO

PRINT 'Orders, order lines, shipments, and returns generated.';
GO
