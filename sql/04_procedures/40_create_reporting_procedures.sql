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

CREATE PROCEDURE reporting.usp_GetSalesPerformance
    @StartDate date,
    @EndDate date,
    @CountryCode char(2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @StartDate IS NULL OR @EndDate IS NULL
        THROW 51000, 'StartDate and EndDate are required.', 1;

    IF @StartDate > @EndDate
        THROW 51001, 'StartDate cannot be later than EndDate.', 1;

    ;WITH Monthly AS
    (
        SELECT
            DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS SalesMonth,
            COUNT_BIG(*) AS CompletedOrders,
            CAST(SUM(NetOrderValue) AS decimal(18,2)) AS NetRevenue,
            CAST(SUM(GrossMarginAmount) AS decimal(18,2)) AS GrossMargin,
            CAST(AVG(NetOrderValue) AS decimal(18,2)) AS AverageOrderValue
        FROM reporting.vw_OrderSummary
        WHERE OrderStatus = 'Completed'
          AND OrderDate BETWEEN @StartDate AND @EndDate
          AND (@CountryCode IS NULL OR CountryCode = @CountryCode)
        GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
    ),
    Compared AS
    (
        SELECT
            SalesMonth,
            CompletedOrders,
            NetRevenue,
            GrossMargin,
            AverageOrderValue,
            LAG(NetRevenue) OVER (ORDER BY SalesMonth) AS PreviousMonthRevenue
        FROM Monthly
    )
    SELECT
        SalesMonth,
        CompletedOrders,
        NetRevenue,
        GrossMargin,
        CAST(
            CASE WHEN NetRevenue = 0 THEN 0 ELSE GrossMargin / NetRevenue END
            AS decimal(10,4)
        ) AS GrossMarginRate,
        AverageOrderValue,
        PreviousMonthRevenue,
        CAST(
            CASE
                WHEN PreviousMonthRevenue IS NULL OR PreviousMonthRevenue = 0 THEN NULL
                ELSE (NetRevenue - PreviousMonthRevenue) / PreviousMonthRevenue
            END AS decimal(10,4)
        ) AS MonthOverMonthRevenueGrowth
    FROM Compared
    ORDER BY SalesMonth;
END;
GO

CREATE PROCEDURE reporting.usp_GetCustomerOrderHistory
    @CustomerID int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM sales.Customer WHERE CustomerID = @CustomerID)
        THROW 51002, 'CustomerID does not exist.', 1;

    SELECT
        CustomerID,
        CustomerNumber,
        CustomerName,
        CustomerType,
        Industry,
        CountryCode,
        FirstOrderDate,
        LastOrderDate,
        NonCancelledOrders,
        CompletedRevenue,
        CompletedGrossMargin,
        AverageCompletedOrderValue
    FROM reporting.vw_CustomerMetrics
    WHERE CustomerID = @CustomerID;

    SELECT
        OrderID,
        OrderNumber,
        OrderDate,
        OrderStatus,
        SalesChannel,
        WarehouseCode,
        LineCount,
        TotalQuantity,
        NetOrderValue,
        GrossMarginAmount,
        ShipmentStatus,
        DeliveredDate,
        IsOnTimeDelivery
    FROM reporting.vw_OrderSummary
    WHERE CustomerID = @CustomerID
    ORDER BY OrderDate DESC, OrderID DESC;
END;
GO

PRINT 'Reporting procedures created.';
GO
