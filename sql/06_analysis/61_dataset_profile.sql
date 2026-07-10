USE B2BOrderAnalytics;
GO
SET NOCOUNT ON;

/*
Dataset profile
---------------
These queries validate that the deterministic synthetic data behaves like a
plausible B2B portfolio instead of a perfectly uniform random sample.
*/

/* 1. Customer purchase behaviour */
;WITH CustomerOrders AS
(
    SELECT
        C.CustomerID,
        C.CustomerType,
        COUNT(O.OrderID) AS TotalOrders,
        SUM(CASE WHEN O.OrderStatus <> 'Cancelled' THEN 1 ELSE 0 END) AS NonCancelledOrders
    FROM sales.Customer C
    LEFT JOIN sales.SalesOrder O
      ON O.CustomerID = C.CustomerID
    GROUP BY C.CustomerID, C.CustomerType
)
SELECT
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN TotalOrders > 0 THEN 1 ELSE 0 END) AS CustomersWithAnyOrder,
    SUM(CASE WHEN NonCancelledOrders = 1 THEN 1 ELSE 0 END) AS OneTimeCustomers,
    SUM(CASE WHEN NonCancelledOrders > 1 THEN 1 ELSE 0 END) AS RepeatCustomers,
    SUM(CASE WHEN TotalOrders = 0 THEN 1 ELSE 0 END) AS CustomersWithoutOrders,
    CAST(
        1.0 * SUM(CASE WHEN NonCancelledOrders > 1 THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN NonCancelledOrders > 0 THEN 1 ELSE 0 END), 0)
        AS decimal(10,4)
    ) AS RepeatCustomerRate
FROM CustomerOrders;
GO

/* 2. Order concentration by customer type */
SELECT
    C.CustomerType,
    COUNT_BIG(*) AS Orders,
    CAST(
        1.0 * COUNT_BIG(*) / SUM(COUNT_BIG(*)) OVER ()
        AS decimal(10,4)
    ) AS OrderShare,
    CAST(AVG(O.NetOrderValue) AS decimal(18,2)) AS AverageOrderValue,
    CAST(SUM(O.NetOrderValue) AS decimal(18,2)) AS NetRevenue
FROM reporting.vw_OrderSummary O
JOIN sales.Customer C
  ON C.CustomerID = O.CustomerID
WHERE O.OrderStatus = 'Completed'
GROUP BY C.CustomerType
ORDER BY Orders DESC;
GO

/* 3. Channel mix and commercial outcome */
SELECT
    SalesChannel,
    COUNT_BIG(*) AS CompletedOrders,
    CAST(
        1.0 * COUNT_BIG(*) / SUM(COUNT_BIG(*)) OVER ()
        AS decimal(10,4)
    ) AS OrderShare,
    CAST(SUM(NetOrderValue) AS decimal(18,2)) AS NetRevenue,
    CAST(AVG(NetOrderValue) AS decimal(18,2)) AS AverageOrderValue,
    CAST(
        SUM(GrossMarginAmount) / NULLIF(SUM(NetOrderValue), 0)
        AS decimal(10,4)
    ) AS GrossMarginRate
FROM reporting.vw_OrderSummary
WHERE OrderStatus = 'Completed'
GROUP BY SalesChannel
ORDER BY CompletedOrders DESC;
GO

/* 4. Product-demand concentration */
;WITH RankedProducts AS
(
    SELECT
        ProductID,
        SKU,
        ProductName,
        CompletedUnits,
        NetRevenue,
        ROW_NUMBER() OVER (ORDER BY CompletedUnits DESC, ProductID) AS DemandRank,
        SUM(CompletedUnits) OVER () AS TotalCompletedUnits
    FROM reporting.vw_ProductPerformance
)
SELECT
    SUM(CASE WHEN DemandRank <= 15 THEN CompletedUnits ELSE 0 END) AS Top15Units,
    MAX(TotalCompletedUnits) AS TotalUnits,
    CAST(
        1.0 * SUM(CASE WHEN DemandRank <= 15 THEN CompletedUnits ELSE 0 END)
        / NULLIF(MAX(TotalCompletedUnits), 0)
        AS decimal(10,4)
    ) AS Top15UnitShare
FROM RankedProducts;
GO

/* 5. Customer-order distribution */
;WITH OrderCounts AS
(
    SELECT
        C.CustomerID,
        C.CustomerType,
        COUNT(O.OrderID) AS NonCancelledOrders
    FROM sales.Customer C
    LEFT JOIN sales.SalesOrder O
      ON O.CustomerID = C.CustomerID
     AND O.OrderStatus <> 'Cancelled'
    GROUP BY C.CustomerID, C.CustomerType
)
SELECT
    CustomerType,
    MIN(NonCancelledOrders) AS MinimumOrders,
    CAST(AVG(1.0 * NonCancelledOrders) AS decimal(10,2)) AS AverageOrders,
    MAX(NonCancelledOrders) AS MaximumOrders
FROM OrderCounts
GROUP BY CustomerType
ORDER BY
    CASE CustomerType
        WHEN 'Enterprise' THEN 1
        WHEN 'MidMarket' THEN 2
        ELSE 3
    END;
GO
