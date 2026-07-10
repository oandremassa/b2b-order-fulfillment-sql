USE B2BOrderAnalytics;
GO
SET NOCOUNT ON;

/*
1. Monthly revenue, gross margin, and month-over-month growth
Business question: Is completed sales performance improving over time?
*/
;WITH Monthly AS
(
    SELECT
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS SalesMonth,
        COUNT_BIG(*) AS CompletedOrders,
        SUM(NetOrderValue) AS NetRevenue,
        SUM(GrossMarginAmount) AS GrossMargin
    FROM reporting.vw_OrderSummary
    WHERE OrderStatus = 'Completed'
    GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
),
Compared AS
(
    SELECT
        *,
        LAG(NetRevenue) OVER (ORDER BY SalesMonth) AS PreviousMonthRevenue
    FROM Monthly
)
SELECT
    SalesMonth,
    CompletedOrders,
    CAST(NetRevenue AS decimal(18,2)) AS NetRevenue,
    CAST(GrossMargin AS decimal(18,2)) AS GrossMargin,
    CAST(GrossMargin / NULLIF(NetRevenue, 0) AS decimal(10,4)) AS GrossMarginRate,
    CAST((NetRevenue - PreviousMonthRevenue) / NULLIF(PreviousMonthRevenue, 0) AS decimal(10,4)) AS MonthOverMonthGrowth
FROM Compared
ORDER BY SalesMonth;
GO

/*
2. Top products by revenue and gross margin
Business question: Which products combine sales volume with profitability?
*/
SELECT TOP (15)
    DENSE_RANK() OVER (ORDER BY NetRevenue DESC) AS RevenueRank,
    SKU,
    ProductName,
    CategoryName,
    CompletedUnits,
    NetRevenue,
    GrossMargin,
    CAST(GrossMargin / NULLIF(NetRevenue, 0) AS decimal(10,4)) AS GrossMarginRate,
    ReturnRate
FROM reporting.vw_ProductPerformance
ORDER BY NetRevenue DESC, SKU;
GO

/*
3. Customer value quartiles
Business question: Which customers should receive greater account-management attention?
*/
;WITH ActiveCustomers AS
(
    SELECT
        CustomerID,
        CustomerNumber,
        CustomerName,
        CustomerType,
        Industry,
        CountryCode,
        NonCancelledOrders,
        CompletedRevenue,
        CompletedGrossMargin
    FROM reporting.vw_CustomerMetrics
    WHERE NonCancelledOrders > 0
),
Scored AS
(
    SELECT
        *,
        NTILE(4) OVER (ORDER BY CompletedRevenue DESC) AS RevenueQuartile
    FROM ActiveCustomers
)
SELECT
    CustomerNumber,
    CustomerName,
    CustomerType,
    Industry,
    CountryCode,
    NonCancelledOrders,
    CompletedRevenue,
    CompletedGrossMargin,
    RevenueQuartile,
    CASE RevenueQuartile
        WHEN 1 THEN 'High Value'
        WHEN 2 THEN 'Upper Mid Value'
        WHEN 3 THEN 'Lower Mid Value'
        ELSE 'Low Value'
    END AS ValueSegment
FROM Scored
ORDER BY RevenueQuartile, CompletedRevenue DESC;
GO

/*
4. Warehouse delivery performance
Business question: Which fulfillment locations meet customer deadlines consistently?
*/
SELECT
    WarehouseCode,
    SUM(FulfilledOrders) AS FulfilledOrders,
    SUM(CompletedOrders) AS CompletedOrders,
    SUM(OnTimeOrders) AS OnTimeOrders,
    CAST(1.0 * SUM(OnTimeOrders) / NULLIF(SUM(CompletedOrders), 0) AS decimal(10,4)) AS OnTimeDeliveryRate,
    CAST(SUM(AverageDeliveryDays * CompletedOrders) / NULLIF(SUM(CompletedOrders), 0) AS decimal(10,2)) AS WeightedAverageDeliveryDays
FROM reporting.vw_FulfillmentPerformance
GROUP BY WarehouseCode
ORDER BY OnTimeDeliveryRate DESC;
GO

/*
5. Return rate by product category
Business question: Which categories generate the most accepted returns?
*/
SELECT
    CategoryName,
    SUM(CompletedUnits) AS CompletedUnits,
    SUM(AcceptedReturnUnits) AS AcceptedReturnUnits,
    CAST(1.0 * SUM(AcceptedReturnUnits) / NULLIF(SUM(CompletedUnits), 0) AS decimal(10,4)) AS ReturnRate,
    CAST(SUM(RefundAmount) AS decimal(18,2)) AS RefundAmount
FROM reporting.vw_ProductPerformance
GROUP BY CategoryName
ORDER BY ReturnRate DESC, CategoryName;
GO

/*
6. Inventory replenishment priorities
Business question: Which product and warehouse combinations need attention first?
*/
SELECT
    WarehouseCode,
    SKU,
    ProductName,
    CategoryName,
    QuantityOnHand,
    ReorderLevel,
    UnitsAboveReorderLevel,
    StockStatus,
    CASE StockStatus
        WHEN 'OutOfStock' THEN 1
        WHEN 'Reorder' THEN 2
        WHEN 'Watch' THEN 3
        ELSE 4
    END AS Priority
FROM reporting.vw_InventoryStatus
WHERE StockStatus <> 'Healthy'
ORDER BY Priority, UnitsAboveReorderLevel, WarehouseCode, SKU;
GO

/*
7. Customer revenue concentration
Business question: How dependent is the company on its largest customers?
*/
;WITH CustomerRevenue AS
(
    SELECT
        CustomerNumber,
        CustomerName,
        CompletedRevenue
    FROM reporting.vw_CustomerMetrics
    WHERE CompletedRevenue > 0
),
Concentration AS
(
    SELECT
        CustomerNumber,
        CustomerName,
        CompletedRevenue,
        SUM(CompletedRevenue) OVER () AS TotalRevenue,
        SUM(CompletedRevenue) OVER (
            ORDER BY CompletedRevenue DESC, CustomerNumber
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS RunningRevenue
    FROM CustomerRevenue
)
SELECT
    CustomerNumber,
    CustomerName,
    CompletedRevenue,
    CAST(CompletedRevenue / NULLIF(TotalRevenue, 0) AS decimal(10,4)) AS RevenueShare,
    CAST(RunningRevenue / NULLIF(TotalRevenue, 0) AS decimal(10,4)) AS CumulativeRevenueShare
FROM Concentration
ORDER BY CompletedRevenue DESC, CustomerNumber;
GO

/*
8. Sales-channel performance
Business question: Which channel produces the best commercial outcome?
*/
SELECT
    SalesChannel,
    COUNT_BIG(*) AS CompletedOrders,
    CAST(SUM(NetOrderValue) AS decimal(18,2)) AS NetRevenue,
    CAST(AVG(NetOrderValue) AS decimal(18,2)) AS AverageOrderValue,
    CAST(SUM(GrossMarginAmount) AS decimal(18,2)) AS GrossMargin,
    CAST(SUM(GrossMarginAmount) / NULLIF(SUM(NetOrderValue), 0) AS decimal(10,4)) AS GrossMarginRate
FROM reporting.vw_OrderSummary
WHERE OrderStatus = 'Completed'
GROUP BY SalesChannel
ORDER BY NetRevenue DESC;
GO

/*
9. Repeat-customer behaviour
Business question: What percentage of customers placed more than one non-cancelled order?
*/
SELECT
    COUNT(*) AS CustomersWithOrders,
    SUM(CASE WHEN NonCancelledOrders = 1 THEN 1 ELSE 0 END) AS OneTimeCustomers,
    SUM(CASE WHEN NonCancelledOrders > 1 THEN 1 ELSE 0 END) AS RepeatCustomers,
    CAST(
        1.0 * SUM(CASE WHEN NonCancelledOrders > 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS decimal(10,4)
    ) AS RepeatCustomerRate
FROM reporting.vw_CustomerMetrics
WHERE NonCancelledOrders > 0;
GO

/*
10. Latest data quality results
Business question: Did the latest validation run pass all critical rules?
*/
DECLARE @LatestRunID bigint = (SELECT MAX(RunID) FROM audit.DataQualityRun);

SELECT
    R.RunID,
    R.StartedAt,
    R.CompletedAt,
    R.OverallStatus,
    R.ChecksPassed,
    R.ChecksFailed
FROM audit.DataQualityRun R
WHERE R.RunID = @LatestRunID;

SELECT
    CheckName,
    Severity,
    FailedRowCount,
    CheckStatus,
    Details
FROM audit.DataQualityResult
WHERE RunID = @LatestRunID
ORDER BY ResultID;
GO
