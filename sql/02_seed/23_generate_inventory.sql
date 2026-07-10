USE [$(DatabaseName)];
GO
SET NOCOUNT ON;

INSERT inventory.StockMovement
(
    ProductID,
    WarehouseID,
    MovementDate,
    MovementType,
    QuantityChange,
    ReferenceType,
    ReferenceID,
    Notes
)
SELECT
    P.ProductID,
    W.WarehouseID,
    '2023-12-31T08:00:00',
    'Opening',
    7000 + CONVERT(int, ABS(CONVERT(bigint, CHECKSUM(CONCAT('opening-', P.ProductID, '-', W.WarehouseID)))) % 2001),
    'InitialLoad',
    NULL,
    N'Opening stock for synthetic dataset'
FROM inventory.Product P
CROSS JOIN inventory.Warehouse W;
GO

;WITH ReceiptDates AS
(
    SELECT ReceiptDate
    FROM (VALUES
        (CONVERT(date, '2024-04-01')),
        (CONVERT(date, '2024-10-01')),
        (CONVERT(date, '2025-04-01')),
        (CONVERT(date, '2025-10-01'))
    ) AS D(ReceiptDate)
)
INSERT inventory.StockMovement
(
    ProductID,
    WarehouseID,
    MovementDate,
    MovementType,
    QuantityChange,
    ReferenceType,
    ReferenceID,
    Notes
)
SELECT
    P.ProductID,
    W.WarehouseID,
    DATEADD(HOUR, 9, CAST(D.ReceiptDate AS datetime2(0))),
    'Receipt',
    150 + CONVERT(int, ABS(CONVERT(bigint, CHECKSUM(CONCAT('receipt-', P.ProductID, '-', W.WarehouseID, '-', D.ReceiptDate)))) % 351),
    'PurchaseReceipt',
    NULL,
    N'Scheduled synthetic replenishment'
FROM inventory.Product P
CROSS JOIN inventory.Warehouse W
CROSS JOIN ReceiptDates D;
GO

INSERT inventory.StockMovement
(
    ProductID,
    WarehouseID,
    MovementDate,
    MovementType,
    QuantityChange,
    ReferenceType,
    ReferenceID,
    Notes
)
SELECT
    OI.ProductID,
    O.WarehouseID,
    DATEADD(HOUR, 16, CAST(COALESCE(S.ShippedDate, O.OrderDate) AS datetime2(0))),
    'Sale',
    -OI.Quantity,
    'OrderItem',
    OI.OrderItemID,
    N'Stock issued for fulfilled sales order'
FROM sales.SalesOrderItem OI
JOIN sales.SalesOrder O
  ON O.OrderID = OI.OrderID
LEFT JOIN sales.Shipment S
  ON S.OrderID = O.OrderID
WHERE O.OrderStatus IN ('Shipped', 'Completed');
GO

INSERT inventory.StockMovement
(
    ProductID,
    WarehouseID,
    MovementDate,
    MovementType,
    QuantityChange,
    ReferenceType,
    ReferenceID,
    Notes
)
SELECT
    OI.ProductID,
    O.WarehouseID,
    DATEADD(HOUR, 10, CAST(R.ReturnDate AS datetime2(0))),
    'Return',
    R.ReturnQuantity,
    'Return',
    R.ReturnID,
    N'Received customer return added back to stock'
FROM sales.ProductReturn R
JOIN sales.SalesOrderItem OI
  ON OI.OrderItemID = R.OrderItemID
JOIN sales.SalesOrder O
  ON O.OrderID = OI.OrderID
WHERE R.ReturnStatus = 'Received';
GO

;WITH CurrentStock AS
(
    SELECT
        M.ProductID,
        M.WarehouseID,
        SUM(M.QuantityChange) AS CurrentQuantity,
        P.ReorderLevel,
        (M.ProductID + M.WarehouseID) % 23 AS StockPattern
    FROM inventory.StockMovement M
    JOIN inventory.Product P
      ON P.ProductID = M.ProductID
    GROUP BY
        M.ProductID,
        M.WarehouseID,
        P.ReorderLevel
),
TargetStock AS
(
    SELECT
        ProductID,
        WarehouseID,
        CurrentQuantity,
        CASE
            WHEN StockPattern = 0 THEN 0
            WHEN StockPattern IN (5, 11) THEN ReorderLevel - 10
            WHEN StockPattern IN (7, 14) THEN ReorderLevel + 20
            ELSE CurrentQuantity
        END AS TargetQuantity
    FROM CurrentStock
)
INSERT inventory.StockMovement
(
    ProductID,
    WarehouseID,
    MovementDate,
    MovementType,
    QuantityChange,
    ReferenceType,
    ReferenceID,
    Notes
)
SELECT
    ProductID,
    WarehouseID,
    '2025-12-31T18:00:00',
    'Adjustment',
    TargetQuantity - CurrentQuantity,
    'SyntheticScenario',
    NULL,
    N'Adjustment used to create realistic inventory risk scenarios'
FROM TargetStock
WHERE TargetQuantity <> CurrentQuantity;
GO

INSERT inventory.StockBalance
(
    ProductID,
    WarehouseID,
    QuantityOnHand,
    LastUpdated
)
SELECT
    ProductID,
    WarehouseID,
    SUM(QuantityChange),
    SYSUTCDATETIME()
FROM inventory.StockMovement
GROUP BY ProductID, WarehouseID;
GO

PRINT 'Inventory movements and balances generated.';
GO
