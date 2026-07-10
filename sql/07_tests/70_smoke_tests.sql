USE [$(DatabaseName)];
GO
SET NOCOUNT ON;

PRINT 'Running smoke tests...';

IF (SELECT COUNT(*) FROM sales.Customer) <> 400
    THROW 52000, 'Smoke test failed: expected 400 customers.', 1;

IF (SELECT COUNT(*) FROM inventory.Product) <> 90
    THROW 52001, 'Smoke test failed: expected 90 products.', 1;

IF (SELECT COUNT(*) FROM inventory.Warehouse) <> 3
    THROW 52002, 'Smoke test failed: expected 3 warehouses.', 1;

IF (SELECT COUNT(*) FROM sales.SalesOrder) <> 5000
    THROW 52003, 'Smoke test failed: expected 5000 orders.', 1;

IF (SELECT COUNT(*) FROM sales.SalesOrderItem) < 5000
    THROW 52004, 'Smoke test failed: expected at least one item per order.', 1;

DECLARE @CustomersWithOrders int;
DECLARE @RepeatCustomers int;
DECLARE @RepeatCustomerRate decimal(10,4);

SELECT
    @CustomersWithOrders = COUNT(*),
    @RepeatCustomers = SUM(CASE WHEN NonCancelledOrders > 1 THEN 1 ELSE 0 END)
FROM reporting.vw_CustomerMetrics
WHERE NonCancelledOrders > 0;

SET @RepeatCustomerRate =
    1.0 * @RepeatCustomers / NULLIF(@CustomersWithOrders, 0);

IF @CustomersWithOrders NOT BETWEEN 300 AND 340
    THROW 52008, 'Smoke test failed: customer participation is outside the expected range.', 1;

IF @RepeatCustomerRate NOT BETWEEN 0.7000 AND 0.8000
    THROW 52009, 'Smoke test failed: repeat-customer rate is outside the expected range.', 1;

IF EXISTS
(
    SELECT SalesChannel
    FROM reporting.vw_OrderSummary
    WHERE OrderStatus = 'Completed'
    GROUP BY SalesChannel
    HAVING COUNT_BIG(*) < 500
)
    THROW 52010, 'Smoke test failed: one sales channel has insufficient completed orders.', 1;

IF EXISTS
(
    SELECT 1
    FROM sales.SalesOrder O
    LEFT JOIN sales.SalesOrderItem OI ON OI.OrderID = O.OrderID
    WHERE OI.OrderItemID IS NULL
)
    THROW 52005, 'Smoke test failed: an order has no items.', 1;

IF EXISTS
(
    SELECT 1
    FROM inventory.StockBalance B
    LEFT JOIN
    (
        SELECT ProductID, WarehouseID, SUM(QuantityChange) AS CalculatedQuantity
        FROM inventory.StockMovement
        GROUP BY ProductID, WarehouseID
    ) M
      ON M.ProductID = B.ProductID
     AND M.WarehouseID = B.WarehouseID
    WHERE B.QuantityOnHand <> COALESCE(M.CalculatedQuantity, 0)
)
    THROW 52006, 'Smoke test failed: stock balances do not reconcile.', 1;

EXEC audit.usp_RunDataQualityChecks;

IF EXISTS
(
    SELECT 1
    FROM audit.DataQualityRun
    WHERE RunID = (SELECT MAX(RunID) FROM audit.DataQualityRun)
      AND OverallStatus <> 'PASS'
)
    THROW 52007, 'Smoke test failed: data quality checks did not pass.', 1;

SELECT
    @CustomersWithOrders AS CustomersWithOrders,
    @RepeatCustomers AS RepeatCustomers,
    @RepeatCustomerRate AS RepeatCustomerRate;

SELECT
    (SELECT COUNT(*) FROM sales.Customer) AS Customers,
    (SELECT COUNT(*) FROM inventory.Product) AS Products,
    (SELECT COUNT(*) FROM sales.SalesOrder) AS Orders,
    (SELECT COUNT(*) FROM sales.SalesOrderItem) AS OrderItems,
    (SELECT COUNT(*) FROM sales.Shipment) AS Shipments,
    (SELECT COUNT(*) FROM sales.ProductReturn) AS Returns,
    (SELECT COUNT(*) FROM inventory.StockMovement) AS StockMovements;

PRINT 'All smoke tests passed.';
GO
