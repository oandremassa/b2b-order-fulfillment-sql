USE [$(DatabaseName)];
GO

ALTER TABLE sales.Customer ADD
    CONSTRAINT UQ_Customer_CustomerNumber UNIQUE (CustomerNumber),
    CONSTRAINT UQ_Customer_Email UNIQUE (Email),
    CONSTRAINT CK_Customer_Type CHECK (CustomerType IN ('SMB', 'MidMarket', 'Enterprise')),
    CONSTRAINT CK_Customer_RegistrationDate CHECK (RegistrationDate <= CAST(GETDATE() AS date));
GO

ALTER TABLE inventory.ProductCategory ADD
    CONSTRAINT UQ_ProductCategory_Name UNIQUE (CategoryName);
GO

ALTER TABLE inventory.Product ADD
    CONSTRAINT UQ_Product_SKU UNIQUE (SKU),
    CONSTRAINT FK_Product_ProductCategory FOREIGN KEY (ProductCategoryID)
        REFERENCES inventory.ProductCategory (ProductCategoryID),
    CONSTRAINT CK_Product_StandardCost CHECK (StandardCost >= 0),
    CONSTRAINT CK_Product_ListPrice CHECK (ListPrice > 0),
    CONSTRAINT CK_Product_ReorderLevel CHECK (ReorderLevel >= 0);
GO

ALTER TABLE inventory.Warehouse ADD
    CONSTRAINT UQ_Warehouse_Code UNIQUE (WarehouseCode);
GO

ALTER TABLE sales.SalesOrder ADD
    CONSTRAINT UQ_SalesOrder_Number UNIQUE (OrderNumber),
    CONSTRAINT FK_SalesOrder_Customer FOREIGN KEY (CustomerID)
        REFERENCES sales.Customer (CustomerID),
    CONSTRAINT FK_SalesOrder_Warehouse FOREIGN KEY (WarehouseID)
        REFERENCES inventory.Warehouse (WarehouseID),
    CONSTRAINT CK_SalesOrder_Dates CHECK (RequiredDeliveryDate >= OrderDate),
    CONSTRAINT CK_SalesOrder_Status CHECK (OrderStatus IN ('Pending', 'Processing', 'Shipped', 'Completed', 'Cancelled')),
    CONSTRAINT CK_SalesOrder_Channel CHECK (SalesChannel IN ('Online', 'SalesRep', 'Partner')),
    CONSTRAINT CK_SalesOrder_PaymentTerms CHECK (PaymentTermsDays BETWEEN 0 AND 90),
    CONSTRAINT CK_SalesOrder_CancellationReason CHECK
    (
        (OrderStatus = 'Cancelled' AND CancellationReason IS NOT NULL)
        OR
        (OrderStatus <> 'Cancelled' AND CancellationReason IS NULL)
    );
GO

ALTER TABLE sales.SalesOrderItem ADD
    CONSTRAINT UQ_SalesOrderItem_OrderLine UNIQUE (OrderID, LineNumber),
    CONSTRAINT FK_SalesOrderItem_Order FOREIGN KEY (OrderID)
        REFERENCES sales.SalesOrder (OrderID),
    CONSTRAINT FK_SalesOrderItem_Product FOREIGN KEY (ProductID)
        REFERENCES inventory.Product (ProductID),
    CONSTRAINT CK_SalesOrderItem_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_SalesOrderItem_UnitPrice CHECK (UnitPrice > 0),
    CONSTRAINT CK_SalesOrderItem_Discount CHECK (DiscountRate BETWEEN 0 AND 0.3000),
    CONSTRAINT CK_SalesOrderItem_UnitCost CHECK (UnitCost >= 0);
GO

ALTER TABLE sales.Shipment ADD
    CONSTRAINT UQ_Shipment_Order UNIQUE (OrderID),
    CONSTRAINT UQ_Shipment_Number UNIQUE (ShipmentNumber),
    CONSTRAINT FK_Shipment_Order FOREIGN KEY (OrderID)
        REFERENCES sales.SalesOrder (OrderID),
    CONSTRAINT CK_Shipment_Status CHECK (ShipmentStatus IN ('Preparing', 'InTransit', 'Delivered', 'Cancelled')),
    CONSTRAINT CK_Shipment_Chronology CHECK
    (
        DeliveredDate IS NULL
        OR ShippedDate IS NULL
        OR DeliveredDate >= ShippedDate
    ),
    CONSTRAINT CK_Shipment_Cost CHECK (ShippingCost >= 0);
GO

ALTER TABLE sales.ProductReturn ADD
    CONSTRAINT FK_ProductReturn_OrderItem FOREIGN KEY (OrderItemID)
        REFERENCES sales.SalesOrderItem (OrderItemID),
    CONSTRAINT CK_ProductReturn_Quantity CHECK (ReturnQuantity > 0),
    CONSTRAINT CK_ProductReturn_Reason CHECK (ReturnReason IN ('Damaged', 'WrongItem', 'NotNeeded', 'QualityIssue', 'LateDelivery')),
    CONSTRAINT CK_ProductReturn_Status CHECK (ReturnStatus IN ('Requested', 'Approved', 'Received', 'Rejected')),
    CONSTRAINT CK_ProductReturn_Refund CHECK (RefundAmount >= 0);
GO

ALTER TABLE inventory.StockMovement ADD
    CONSTRAINT FK_StockMovement_Product FOREIGN KEY (ProductID)
        REFERENCES inventory.Product (ProductID),
    CONSTRAINT FK_StockMovement_Warehouse FOREIGN KEY (WarehouseID)
        REFERENCES inventory.Warehouse (WarehouseID),
    CONSTRAINT CK_StockMovement_Type CHECK (MovementType IN ('Opening', 'Receipt', 'Sale', 'Return', 'Adjustment')),
    CONSTRAINT CK_StockMovement_Quantity CHECK (QuantityChange <> 0);
GO

ALTER TABLE inventory.StockBalance ADD
    CONSTRAINT FK_StockBalance_Product FOREIGN KEY (ProductID)
        REFERENCES inventory.Product (ProductID),
    CONSTRAINT FK_StockBalance_Warehouse FOREIGN KEY (WarehouseID)
        REFERENCES inventory.Warehouse (WarehouseID),
    CONSTRAINT CK_StockBalance_Quantity CHECK (QuantityOnHand >= 0);
GO

ALTER TABLE audit.DataQualityResult ADD
    CONSTRAINT FK_DataQualityResult_Run FOREIGN KEY (RunID)
        REFERENCES audit.DataQualityRun (RunID),
    CONSTRAINT CK_DataQualityResult_Severity CHECK (Severity IN ('Info', 'Warning', 'Error')),
    CONSTRAINT CK_DataQualityResult_Status CHECK (CheckStatus IN ('PASS', 'FAIL'));
GO

PRINT 'Constraints created.';
GO
