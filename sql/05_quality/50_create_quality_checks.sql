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

CREATE PROCEDURE audit.usp_RunDataQualityChecks
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RunID bigint;
    DECLARE @FailedRows bigint;

    INSERT audit.DataQualityRun (StartedAt)
    VALUES (SYSUTCDATETIME());

    SET @RunID = SCOPE_IDENTITY();

    BEGIN TRY
        SELECT @FailedRows = COUNT_BIG(*)
        FROM
        (
            SELECT Email
            FROM sales.Customer
            GROUP BY Email
            HAVING COUNT(*) > 1
        ) D;

        INSERT audit.DataQualityResult
            (RunID, CheckName, Severity, FailedRowCount, CheckStatus, Details)
        VALUES
            (@RunID, N'Duplicate customer email', 'Error', @FailedRows,
             CASE WHEN @FailedRows = 0 THEN 'PASS' ELSE 'FAIL' END,
             N'Customer email must be unique.');

        SELECT @FailedRows = COUNT_BIG(*)
        FROM
        (
            SELECT SKU
            FROM inventory.Product
            GROUP BY SKU
            HAVING COUNT(*) > 1
        ) D;

        INSERT audit.DataQualityResult
            (RunID, CheckName, Severity, FailedRowCount, CheckStatus, Details)
        VALUES
            (@RunID, N'Duplicate product SKU', 'Error', @FailedRows,
             CASE WHEN @FailedRows = 0 THEN 'PASS' ELSE 'FAIL' END,
             N'Product SKU must be unique.');

        SELECT @FailedRows = COUNT_BIG(*)
        FROM sales.SalesOrderItem OI
        LEFT JOIN sales.SalesOrder O ON O.OrderID = OI.OrderID
        LEFT JOIN inventory.Product P ON P.ProductID = OI.ProductID
        WHERE O.OrderID IS NULL OR P.ProductID IS NULL;

        INSERT audit.DataQualityResult
            (RunID, CheckName, Severity, FailedRowCount, CheckStatus, Details)
        VALUES
            (@RunID, N'Orphan order items', 'Error', @FailedRows,
             CASE WHEN @FailedRows = 0 THEN 'PASS' ELSE 'FAIL' END,
             N'Every order item must reference a valid order and product.');

        SELECT @FailedRows = COUNT_BIG(*)
        FROM sales.Shipment
        WHERE DeliveredDate IS NOT NULL
          AND (ShippedDate IS NULL OR DeliveredDate < ShippedDate);

        INSERT audit.DataQualityResult
            (RunID, CheckName, Severity, FailedRowCount, CheckStatus, Details)
        VALUES
            (@RunID, N'Invalid shipment chronology', 'Error', @FailedRows,
             CASE WHEN @FailedRows = 0 THEN 'PASS' ELSE 'FAIL' END,
             N'Delivered date cannot precede shipped date.');

        SELECT @FailedRows = COUNT_BIG(*)
        FROM sales.ProductReturn R
        JOIN sales.SalesOrderItem OI ON OI.OrderItemID = R.OrderItemID
        WHERE R.ReturnQuantity > OI.Quantity;

        INSERT audit.DataQualityResult
            (RunID, CheckName, Severity, FailedRowCount, CheckStatus, Details)
        VALUES
            (@RunID, N'Return quantity exceeds ordered quantity', 'Error', @FailedRows,
             CASE WHEN @FailedRows = 0 THEN 'PASS' ELSE 'FAIL' END,
             N'Returned units cannot exceed ordered units.');

        SELECT @FailedRows = COUNT_BIG(*)
        FROM inventory.StockBalance B
        LEFT JOIN
        (
            SELECT ProductID, WarehouseID, SUM(QuantityChange) AS CalculatedQuantity
            FROM inventory.StockMovement
            GROUP BY ProductID, WarehouseID
        ) M
          ON M.ProductID = B.ProductID
         AND M.WarehouseID = B.WarehouseID
        WHERE B.QuantityOnHand <> COALESCE(M.CalculatedQuantity, 0);

        INSERT audit.DataQualityResult
            (RunID, CheckName, Severity, FailedRowCount, CheckStatus, Details)
        VALUES
            (@RunID, N'Stock balance does not match movements', 'Error', @FailedRows,
             CASE WHEN @FailedRows = 0 THEN 'PASS' ELSE 'FAIL' END,
             N'Balance must equal the sum of signed movements.');

        SELECT @FailedRows = COUNT_BIG(*)
        FROM inventory.StockBalance
        WHERE QuantityOnHand < 0;

        INSERT audit.DataQualityResult
            (RunID, CheckName, Severity, FailedRowCount, CheckStatus, Details)
        VALUES
            (@RunID, N'Negative stock balance', 'Error', @FailedRows,
             CASE WHEN @FailedRows = 0 THEN 'PASS' ELSE 'FAIL' END,
             N'Current stock cannot be negative.');

        SELECT @FailedRows = COUNT_BIG(*)
        FROM sales.SalesOrder O
        LEFT JOIN sales.Shipment S ON S.OrderID = O.OrderID
        WHERE O.OrderStatus = 'Completed'
          AND (S.ShipmentID IS NULL OR S.ShipmentStatus <> 'Delivered' OR S.DeliveredDate IS NULL);

        INSERT audit.DataQualityResult
            (RunID, CheckName, Severity, FailedRowCount, CheckStatus, Details)
        VALUES
            (@RunID, N'Completed order without delivered shipment', 'Error', @FailedRows,
             CASE WHEN @FailedRows = 0 THEN 'PASS' ELSE 'FAIL' END,
             N'Completed orders require a delivered shipment.');

        SELECT @FailedRows = COUNT_BIG(*)
        FROM sales.SalesOrder O
        JOIN sales.Shipment S ON S.OrderID = O.OrderID
        WHERE O.OrderStatus = 'Cancelled'
          AND S.ShipmentStatus <> 'Cancelled';

        INSERT audit.DataQualityResult
            (RunID, CheckName, Severity, FailedRowCount, CheckStatus, Details)
        VALUES
            (@RunID, N'Cancelled order with active shipment', 'Error', @FailedRows,
             CASE WHEN @FailedRows = 0 THEN 'PASS' ELSE 'FAIL' END,
             N'Cancelled orders should not have active shipments.');

        SELECT @FailedRows = COUNT_BIG(*)
        FROM sales.SalesOrder O
        LEFT JOIN sales.SalesOrderItem OI ON OI.OrderID = O.OrderID
        WHERE OI.OrderItemID IS NULL;

        INSERT audit.DataQualityResult
            (RunID, CheckName, Severity, FailedRowCount, CheckStatus, Details)
        VALUES
            (@RunID, N'Order without order items', 'Error', @FailedRows,
             CASE WHEN @FailedRows = 0 THEN 'PASS' ELSE 'FAIL' END,
             N'Every order must contain at least one order line.');

        UPDATE audit.DataQualityRun
        SET CompletedAt = SYSUTCDATETIME(),
            ChecksPassed = (SELECT COUNT(*) FROM audit.DataQualityResult WHERE RunID = @RunID AND CheckStatus = 'PASS'),
            ChecksFailed = (SELECT COUNT(*) FROM audit.DataQualityResult WHERE RunID = @RunID AND CheckStatus = 'FAIL'),
            OverallStatus = CASE
                WHEN EXISTS
                (
                    SELECT 1
                    FROM audit.DataQualityResult
                    WHERE RunID = @RunID
                      AND CheckStatus = 'FAIL'
                      AND Severity = 'Error'
                ) THEN 'FAIL'
                ELSE 'PASS'
            END
        WHERE RunID = @RunID;

        SELECT
            RunID,
            StartedAt,
            CompletedAt,
            OverallStatus,
            ChecksPassed,
            ChecksFailed
        FROM audit.DataQualityRun
        WHERE RunID = @RunID;

        SELECT
            CheckName,
            Severity,
            FailedRowCount,
            CheckStatus,
            Details,
            CheckedAt
        FROM audit.DataQualityResult
        WHERE RunID = @RunID
        ORDER BY ResultID;
    END TRY
    BEGIN CATCH
        UPDATE audit.DataQualityRun
        SET CompletedAt = SYSUTCDATETIME(),
            OverallStatus = 'FAIL'
        WHERE RunID = @RunID;

        THROW;
    END CATCH;
END;
GO

PRINT 'Data quality procedure created.';
GO
