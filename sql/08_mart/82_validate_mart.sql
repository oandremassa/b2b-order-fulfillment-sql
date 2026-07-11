SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE [$(DatabaseName)];
GO

CREATE OR ALTER PROCEDURE mart.usp_ValidateReportingMart
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Results table
    (
        CheckName varchar(100) NOT NULL,
        ExpectedValue decimal(28,4) NULL,
        ActualValue decimal(28,4) NULL,
        CheckStatus varchar(10) NOT NULL,
        Details varchar(250) NOT NULL
    );

    DECLARE @Expected decimal(28,4);
    DECLARE @Actual decimal(28,4);

    SELECT @Expected = COUNT(*) FROM sales.Customer;
    SELECT @Actual = COUNT(*) FROM mart.DimCustomer;
    INSERT @Results VALUES ('Customer dimension row count', @Expected, @Actual, CASE WHEN @Expected = @Actual THEN 'PASS' ELSE 'FAIL' END, 'DimCustomer must contain one row per source customer.');

    SELECT @Expected = COUNT(*) FROM inventory.Product;
    SELECT @Actual = COUNT(*) FROM mart.DimProduct;
    INSERT @Results VALUES ('Product dimension row count', @Expected, @Actual, CASE WHEN @Expected = @Actual THEN 'PASS' ELSE 'FAIL' END, 'DimProduct must contain one row per source product.');

    SELECT @Expected = COUNT(*) FROM sales.SalesOrder;
    SELECT @Actual = COUNT(*) FROM mart.FactOrder;
    INSERT @Results VALUES ('Order fact row count', @Expected, @Actual, CASE WHEN @Expected = @Actual THEN 'PASS' ELSE 'FAIL' END, 'FactOrder grain is one row per order.');

    SELECT @Expected = COUNT(*) FROM sales.SalesOrderItem;
    SELECT @Actual = COUNT(*) FROM mart.FactSalesLine;
    INSERT @Results VALUES ('Sales line fact row count', @Expected, @Actual, CASE WHEN @Expected = @Actual THEN 'PASS' ELSE 'FAIL' END, 'FactSalesLine grain is one row per order item.');

    SELECT @Expected = COUNT(*) FROM sales.ProductReturn;
    SELECT @Actual = COUNT(*) FROM mart.FactReturn;
    INSERT @Results VALUES ('Return fact row count', @Expected, @Actual, CASE WHEN @Expected = @Actual THEN 'PASS' ELSE 'FAIL' END, 'FactReturn grain is one row per return record.');

    SELECT @Expected = COUNT(*) FROM inventory.StockBalance;
    SELECT @Actual = COUNT(*) FROM mart.FactInventorySnapshot;
    INSERT @Results VALUES ('Inventory snapshot row count', @Expected, @Actual, CASE WHEN @Expected = @Actual THEN 'PASS' ELSE 'FAIL' END, 'The snapshot contains one row per product and warehouse.');

    SELECT @Expected = SUM(NetOrderValue) FROM reporting.vw_OrderSummary WHERE OrderStatus = 'Completed';
    SELECT @Actual = SUM(NetOrderValue) FROM mart.FactOrder WHERE OrderStatus = 'Completed';
    INSERT @Results VALUES ('Completed order revenue reconciliation', @Expected, @Actual, CASE WHEN ABS(@Expected - @Actual) < 0.01 THEN 'PASS' ELSE 'FAIL' END, 'Completed order revenue must reconcile to the reporting view.');

    SELECT @Expected = SUM(LineNetAmount) FROM reporting.vw_OrderLineDetails WHERE OrderStatus = 'Completed';
    SELECT @Actual = SUM(NetSalesAmount) FROM mart.FactSalesLine WHERE IsCompleted = 1;
    INSERT @Results VALUES ('Completed sales line revenue reconciliation', @Expected, @Actual, CASE WHEN ABS(@Expected - @Actual) < 0.01 THEN 'PASS' ELSE 'FAIL' END, 'Completed line revenue must reconcile to the operational reporting view.');

    SELECT @Expected = SUM(CASE WHEN ReturnStatus IN ('Approved', 'Received') THEN RefundAmount ELSE 0 END) FROM sales.ProductReturn;
    SELECT @Actual = SUM(CASE WHEN IsAcceptedReturn = 1 THEN RefundAmount ELSE 0 END) FROM mart.FactReturn;
    INSERT @Results VALUES ('Accepted refund reconciliation', @Expected, @Actual, CASE WHEN ABS(@Expected - @Actual) < 0.01 THEN 'PASS' ELSE 'FAIL' END, 'Accepted refund amount must reconcile to source returns.');

    SELECT @Expected = SUM(QuantityOnHand) FROM inventory.StockBalance;
    SELECT @Actual = SUM(QuantityOnHand) FROM mart.FactInventorySnapshot;
    INSERT @Results VALUES ('Inventory quantity reconciliation', @Expected, @Actual, CASE WHEN @Expected = @Actual THEN 'PASS' ELSE 'FAIL' END, 'Inventory quantity must reconcile to current stock balances.');

    SELECT * FROM @Results ORDER BY CheckName;

    IF EXISTS (SELECT 1 FROM @Results WHERE CheckStatus = 'FAIL')
        THROW 53000, 'Reporting mart validation failed.', 1;
END;
GO

EXEC mart.usp_ValidateReportingMart;
GO

SELECT
    (SELECT COUNT(*) FROM mart.DimDate) AS Dates,
    (SELECT COUNT(*) FROM mart.DimCustomer) AS Customers,
    (SELECT COUNT(*) FROM mart.DimProduct) AS Products,
    (SELECT COUNT(*) FROM mart.DimWarehouse) AS Warehouses,
    (SELECT COUNT(*) FROM mart.FactOrder) AS Orders,
    (SELECT COUNT(*) FROM mart.FactSalesLine) AS SalesLines,
    (SELECT COUNT(*) FROM mart.FactReturn) AS Returns,
    (SELECT COUNT(*) FROM mart.FactInventorySnapshot) AS InventoryPositions;
GO

PRINT 'Reporting mart validation passed.';
GO
