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

CREATE INDEX IX_Customer_CountryType
ON sales.Customer (CountryCode, CustomerType)
INCLUDE (CustomerName, Industry, IsActive);
GO

CREATE INDEX IX_SalesOrder_OrderDateStatus
ON sales.SalesOrder (OrderDate, OrderStatus)
INCLUDE (CustomerID, WarehouseID, SalesChannel, RequiredDeliveryDate);
GO

CREATE INDEX IX_SalesOrder_CustomerDate
ON sales.SalesOrder (CustomerID, OrderDate DESC)
INCLUDE (OrderStatus, SalesChannel, WarehouseID);
GO

CREATE INDEX IX_SalesOrderItem_Product
ON sales.SalesOrderItem (ProductID)
INCLUDE (OrderID, Quantity, UnitPrice, DiscountRate, UnitCost);
GO

CREATE INDEX IX_Shipment_StatusDates
ON sales.Shipment (ShipmentStatus, ShippedDate, DeliveredDate)
INCLUDE (OrderID, Carrier, ShippingCost);
GO

CREATE INDEX IX_ProductReturn_OrderItemStatus
ON sales.ProductReturn (OrderItemID, ReturnStatus)
INCLUDE (ReturnDate, ReturnQuantity, ReturnReason, RefundAmount);
GO

CREATE INDEX IX_StockMovement_ProductWarehouseDate
ON inventory.StockMovement (ProductID, WarehouseID, MovementDate)
INCLUDE (MovementType, QuantityChange, ReferenceType, ReferenceID);
GO

PRINT 'Indexes created.';
GO
