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

CREATE VIEW reporting.vw_OrderLineDetails
AS
SELECT
    O.OrderID,
    O.OrderNumber,
    O.OrderDate,
    O.RequiredDeliveryDate,
    O.OrderStatus,
    O.SalesChannel,
    C.CustomerID,
    C.CustomerNumber,
    C.CustomerName,
    C.CustomerType,
    C.Industry,
    C.CountryCode,
    W.WarehouseID,
    W.WarehouseCode,
    W.WarehouseName,
    OI.OrderItemID,
    OI.LineNumber,
    P.ProductID,
    P.SKU,
    P.ProductName,
    PC.CategoryName,
    OI.Quantity,
    OI.UnitPrice,
    OI.DiscountRate,
    OI.UnitCost,
    OI.LineGrossAmount,
    OI.LineNetAmount,
    OI.LineCostAmount,
    CAST(OI.LineNetAmount - OI.LineCostAmount AS decimal(18,2)) AS GrossMarginAmount,
    S.ShipmentStatus,
    S.ShippedDate,
    S.DeliveredDate,
    S.Carrier,
    CASE
        WHEN S.DeliveredDate IS NULL THEN NULL
        ELSE DATEDIFF(DAY, O.OrderDate, S.DeliveredDate)
    END AS DeliveryDays,
    CASE
        WHEN S.DeliveredDate IS NULL THEN NULL
        WHEN S.DeliveredDate <= O.RequiredDeliveryDate THEN 1
        ELSE 0
    END AS IsOnTimeDelivery
FROM sales.SalesOrder O
JOIN sales.Customer C
  ON C.CustomerID = O.CustomerID
JOIN inventory.Warehouse W
  ON W.WarehouseID = O.WarehouseID
JOIN sales.SalesOrderItem OI
  ON OI.OrderID = O.OrderID
JOIN inventory.Product P
  ON P.ProductID = OI.ProductID
JOIN inventory.ProductCategory PC
  ON PC.ProductCategoryID = P.ProductCategoryID
LEFT JOIN sales.Shipment S
  ON S.OrderID = O.OrderID;
GO

CREATE VIEW reporting.vw_OrderSummary
AS
SELECT
    O.OrderID,
    O.OrderNumber,
    O.OrderDate,
    O.RequiredDeliveryDate,
    O.OrderStatus,
    O.SalesChannel,
    O.PaymentTermsDays,
    C.CustomerID,
    C.CustomerNumber,
    C.CustomerName,
    C.CustomerType,
    C.CountryCode,
    W.WarehouseID,
    W.WarehouseCode,
    COUNT_BIG(OI.OrderItemID) AS LineCount,
    SUM(OI.Quantity) AS TotalQuantity,
    CAST(SUM(OI.LineGrossAmount) AS decimal(18,2)) AS GrossOrderValue,
    CAST(SUM(OI.LineNetAmount) AS decimal(18,2)) AS NetOrderValue,
    CAST(SUM(OI.LineCostAmount) AS decimal(18,2)) AS CostAmount,
    CAST(SUM(OI.LineNetAmount - OI.LineCostAmount) AS decimal(18,2)) AS GrossMarginAmount,
    S.ShipmentStatus,
    S.ShippedDate,
    S.DeliveredDate,
    S.Carrier,
    S.ShippingCost,
    CASE
        WHEN S.DeliveredDate IS NULL THEN NULL
        ELSE DATEDIFF(DAY, O.OrderDate, S.DeliveredDate)
    END AS DeliveryDays,
    CASE
        WHEN S.DeliveredDate IS NULL THEN NULL
        WHEN S.DeliveredDate <= O.RequiredDeliveryDate THEN 1
        ELSE 0
    END AS IsOnTimeDelivery
FROM sales.SalesOrder O
JOIN sales.Customer C
  ON C.CustomerID = O.CustomerID
JOIN inventory.Warehouse W
  ON W.WarehouseID = O.WarehouseID
JOIN sales.SalesOrderItem OI
  ON OI.OrderID = O.OrderID
LEFT JOIN sales.Shipment S
  ON S.OrderID = O.OrderID
GROUP BY
    O.OrderID,
    O.OrderNumber,
    O.OrderDate,
    O.RequiredDeliveryDate,
    O.OrderStatus,
    O.SalesChannel,
    O.PaymentTermsDays,
    C.CustomerID,
    C.CustomerNumber,
    C.CustomerName,
    C.CustomerType,
    C.CountryCode,
    W.WarehouseID,
    W.WarehouseCode,
    S.ShipmentStatus,
    S.ShippedDate,
    S.DeliveredDate,
    S.Carrier,
    S.ShippingCost;
GO

CREATE VIEW reporting.vw_MonthlySales
AS
SELECT
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS SalesMonth,
    CountryCode,
    SalesChannel,
    COUNT_BIG(*) AS CompletedOrders,
    CAST(SUM(NetOrderValue) AS decimal(18,2)) AS NetRevenue,
    CAST(SUM(GrossMarginAmount) AS decimal(18,2)) AS GrossMargin,
    CAST(AVG(NetOrderValue) AS decimal(18,2)) AS AverageOrderValue
FROM reporting.vw_OrderSummary
WHERE OrderStatus = 'Completed'
GROUP BY
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1),
    CountryCode,
    SalesChannel;
GO

CREATE VIEW reporting.vw_CustomerMetrics
AS
SELECT
    C.CustomerID,
    C.CustomerNumber,
    C.CustomerName,
    C.CustomerType,
    C.Industry,
    C.CountryCode,
    MIN(CASE WHEN O.OrderStatus <> 'Cancelled' THEN O.OrderDate END) AS FirstOrderDate,
    MAX(CASE WHEN O.OrderStatus <> 'Cancelled' THEN O.OrderDate END) AS LastOrderDate,
    SUM(CASE WHEN O.OrderStatus <> 'Cancelled' THEN 1 ELSE 0 END) AS NonCancelledOrders,
    CAST(COALESCE(SUM(CASE WHEN O.OrderStatus = 'Completed' THEN O.NetOrderValue END), 0) AS decimal(18,2)) AS CompletedRevenue,
    CAST(COALESCE(SUM(CASE WHEN O.OrderStatus = 'Completed' THEN O.GrossMarginAmount END), 0) AS decimal(18,2)) AS CompletedGrossMargin,
    CAST(COALESCE(AVG(CASE WHEN O.OrderStatus = 'Completed' THEN O.NetOrderValue END), 0) AS decimal(18,2)) AS AverageCompletedOrderValue
FROM sales.Customer C
LEFT JOIN reporting.vw_OrderSummary O
  ON O.CustomerID = C.CustomerID
GROUP BY
    C.CustomerID,
    C.CustomerNumber,
    C.CustomerName,
    C.CustomerType,
    C.Industry,
    C.CountryCode;
GO

CREATE VIEW reporting.vw_ProductPerformance
AS
WITH SalesAgg AS
(
    SELECT
        OI.ProductID,
        SUM(CASE WHEN O.OrderStatus = 'Completed' THEN OI.Quantity ELSE 0 END) AS CompletedUnits,
        SUM(CASE WHEN O.OrderStatus = 'Completed' THEN OI.LineNetAmount ELSE 0 END) AS NetRevenue,
        SUM(CASE WHEN O.OrderStatus = 'Completed' THEN OI.LineNetAmount - OI.LineCostAmount ELSE 0 END) AS GrossMargin
    FROM sales.SalesOrderItem OI
    JOIN sales.SalesOrder O
      ON O.OrderID = OI.OrderID
    GROUP BY OI.ProductID
),
ReturnAgg AS
(
    SELECT
        OI.ProductID,
        SUM(CASE WHEN R.ReturnStatus IN ('Approved', 'Received') THEN R.ReturnQuantity ELSE 0 END) AS AcceptedReturnUnits,
        SUM(CASE WHEN R.ReturnStatus IN ('Approved', 'Received') THEN R.RefundAmount ELSE 0 END) AS RefundAmount
    FROM sales.ProductReturn R
    JOIN sales.SalesOrderItem OI
      ON OI.OrderItemID = R.OrderItemID
    GROUP BY OI.ProductID
)
SELECT
    P.ProductID,
    P.SKU,
    P.ProductName,
    C.CategoryName,
    COALESCE(S.CompletedUnits, 0) AS CompletedUnits,
    CAST(COALESCE(S.NetRevenue, 0) AS decimal(18,2)) AS NetRevenue,
    CAST(COALESCE(S.GrossMargin, 0) AS decimal(18,2)) AS GrossMargin,
    COALESCE(R.AcceptedReturnUnits, 0) AS AcceptedReturnUnits,
    CAST(COALESCE(R.RefundAmount, 0) AS decimal(18,2)) AS RefundAmount,
    CAST(
        CASE
            WHEN COALESCE(S.CompletedUnits, 0) = 0 THEN 0
            ELSE 1.0 * COALESCE(R.AcceptedReturnUnits, 0) / S.CompletedUnits
        END AS decimal(10,4)
    ) AS ReturnRate
FROM inventory.Product P
JOIN inventory.ProductCategory C
  ON C.ProductCategoryID = P.ProductCategoryID
LEFT JOIN SalesAgg S
  ON S.ProductID = P.ProductID
LEFT JOIN ReturnAgg R
  ON R.ProductID = P.ProductID;
GO

CREATE VIEW reporting.vw_InventoryStatus
AS
SELECT
    B.ProductID,
    P.SKU,
    P.ProductName,
    C.CategoryName,
    B.WarehouseID,
    W.WarehouseCode,
    W.WarehouseName,
    B.QuantityOnHand,
    P.ReorderLevel,
    B.QuantityOnHand - P.ReorderLevel AS UnitsAboveReorderLevel,
    CASE
        WHEN B.QuantityOnHand = 0 THEN 'OutOfStock'
        WHEN B.QuantityOnHand <= P.ReorderLevel THEN 'Reorder'
        WHEN B.QuantityOnHand <= P.ReorderLevel * 2 THEN 'Watch'
        ELSE 'Healthy'
    END AS StockStatus,
    B.LastUpdated
FROM inventory.StockBalance B
JOIN inventory.Product P
  ON P.ProductID = B.ProductID
JOIN inventory.ProductCategory C
  ON C.ProductCategoryID = P.ProductCategoryID
JOIN inventory.Warehouse W
  ON W.WarehouseID = B.WarehouseID;
GO

CREATE VIEW reporting.vw_FulfillmentPerformance
AS
SELECT
    DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1) AS OrderMonth,
    O.WarehouseID,
    O.WarehouseCode,
    COUNT_BIG(*) AS FulfilledOrders,
    SUM(CASE WHEN O.OrderStatus = 'Completed' THEN 1 ELSE 0 END) AS CompletedOrders,
    SUM(CASE WHEN O.IsOnTimeDelivery = 1 THEN 1 ELSE 0 END) AS OnTimeOrders,
    CAST(
        CASE
            WHEN SUM(CASE WHEN O.OrderStatus = 'Completed' THEN 1 ELSE 0 END) = 0 THEN NULL
            ELSE 1.0 * SUM(CASE WHEN O.IsOnTimeDelivery = 1 THEN 1 ELSE 0 END)
                / SUM(CASE WHEN O.OrderStatus = 'Completed' THEN 1 ELSE 0 END)
        END AS decimal(10,4)
    ) AS OnTimeDeliveryRate,
    CAST(AVG(CASE WHEN O.OrderStatus = 'Completed' THEN 1.0 * O.DeliveryDays END) AS decimal(10,2)) AS AverageDeliveryDays
FROM reporting.vw_OrderSummary O
WHERE O.OrderStatus IN ('Shipped', 'Completed')
GROUP BY
    DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1),
    O.WarehouseID,
    O.WarehouseCode;
GO

PRINT 'Reporting views created.';
GO
