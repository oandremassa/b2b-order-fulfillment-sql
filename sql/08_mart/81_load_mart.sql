SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE [$(DatabaseName)];
GO

CREATE OR ALTER PROCEDURE mart.usp_LoadReportingMart
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM mart.FactInventorySnapshot;
        DELETE FROM mart.FactReturn;
        DELETE FROM mart.FactSalesLine;
        DELETE FROM mart.FactOrder;
        DELETE FROM mart.DimSalesChannel;
        DELETE FROM mart.DimWarehouse;
        DELETE FROM mart.DimProduct;
        DELETE FROM mart.DimCustomer;
        DELETE FROM mart.DimDate;

        DBCC CHECKIDENT ('mart.DimCustomer', RESEED, 0) WITH NO_INFOMSGS;
        DBCC CHECKIDENT ('mart.DimProduct', RESEED, 0) WITH NO_INFOMSGS;
        DBCC CHECKIDENT ('mart.DimWarehouse', RESEED, 0) WITH NO_INFOMSGS;

        DECLARE @MinDate date = DATEFROMPARTS(
            YEAR((SELECT MIN(OrderDate) FROM sales.SalesOrder)) - 1,
            1,
            1
        );

        DECLARE @MaxDate date = EOMONTH
        (
            (
                SELECT MAX(SourceDate)
                FROM
                (
                    SELECT MAX(OrderDate) AS SourceDate FROM sales.SalesOrder
                    UNION ALL SELECT MAX(RequiredDeliveryDate) FROM sales.SalesOrder
                    UNION ALL SELECT MAX(ShippedDate) FROM sales.Shipment
                    UNION ALL SELECT MAX(DeliveredDate) FROM sales.Shipment
                    UNION ALL SELECT MAX(ReturnDate) FROM sales.ProductReturn
                ) D
            )
        );

        ;WITH Dates AS
        (
            SELECT @MinDate AS FullDate
            UNION ALL
            SELECT DATEADD(DAY, 1, FullDate)
            FROM Dates
            WHERE FullDate < @MaxDate
        )
        INSERT mart.DimDate
        (
            DateKey,
            FullDate,
            CalendarYear,
            CalendarQuarter,
            QuarterLabel,
            MonthNumber,
            MonthName,
            YearMonthNumber,
            YearMonthLabel,
            DayOfMonth,
            DayName,
            IsWeekend
        )
        SELECT
            CONVERT(int, CONVERT(char(8), FullDate, 112)),
            FullDate,
            YEAR(FullDate),
            DATEPART(QUARTER, FullDate),
            CONCAT('Q', DATEPART(QUARTER, FullDate)),
            MONTH(FullDate),
            CASE MONTH(FullDate)
                WHEN 1 THEN 'January' WHEN 2 THEN 'February' WHEN 3 THEN 'March'
                WHEN 4 THEN 'April' WHEN 5 THEN 'May' WHEN 6 THEN 'June'
                WHEN 7 THEN 'July' WHEN 8 THEN 'August' WHEN 9 THEN 'September'
                WHEN 10 THEN 'October' WHEN 11 THEN 'November' ELSE 'December'
            END,
            YEAR(FullDate) * 100 + MONTH(FullDate),
            CONVERT(char(7), FullDate, 126),
            DAY(FullDate),
            CASE DATEDIFF(DAY, '19000101', FullDate) % 7
                WHEN 0 THEN 'Monday' WHEN 1 THEN 'Tuesday' WHEN 2 THEN 'Wednesday'
                WHEN 3 THEN 'Thursday' WHEN 4 THEN 'Friday' WHEN 5 THEN 'Saturday'
                ELSE 'Sunday'
            END,
            CASE WHEN DATEDIFF(DAY, '19000101', FullDate) % 7 IN (5, 6) THEN 1 ELSE 0 END
        FROM Dates
        OPTION (MAXRECURSION 0);

        INSERT mart.DimCustomer
        (
            SourceCustomerID,
            CustomerNumber,
            CustomerName,
            CustomerType,
            Industry,
            CountryCode,
            City,
            RegistrationDate,
            IsActive
        )
        SELECT
            CustomerID,
            CustomerNumber,
            CustomerName,
            CustomerType,
            Industry,
            CountryCode,
            City,
            RegistrationDate,
            IsActive
        FROM sales.Customer;

        INSERT mart.DimProduct
        (
            SourceProductID,
            SKU,
            ProductName,
            CategoryName,
            StandardCost,
            ListPrice,
            ReorderLevel,
            IsActive
        )
        SELECT
            P.ProductID,
            P.SKU,
            P.ProductName,
            C.CategoryName,
            P.StandardCost,
            P.ListPrice,
            P.ReorderLevel,
            P.IsActive
        FROM inventory.Product P
        JOIN inventory.ProductCategory C
            ON C.ProductCategoryID = P.ProductCategoryID;

        INSERT mart.DimWarehouse
        (
            SourceWarehouseID,
            WarehouseCode,
            WarehouseName,
            City,
            CountryCode,
            IsActive
        )
        SELECT
            WarehouseID,
            WarehouseCode,
            WarehouseName,
            City,
            CountryCode,
            IsActive
        FROM inventory.Warehouse;

        INSERT mart.DimSalesChannel (SalesChannelKey, SalesChannel)
        VALUES
            (1, 'Online'),
            (2, 'SalesRep'),
            (3, 'Partner');

        INSERT mart.FactOrder
        (
            OrderKey,
            OrderNumber,
            OrderDateKey,
            RequiredDeliveryDateKey,
            ShippedDateKey,
            DeliveredDateKey,
            CustomerKey,
            WarehouseKey,
            SalesChannelKey,
            OrderStatus,
            ShipmentStatus,
            Carrier,
            PaymentTermsDays,
            LineCount,
            TotalQuantity,
            GrossOrderValue,
            NetOrderValue,
            CostAmount,
            GrossMarginAmount,
            ShippingCost,
            DeliveryDays,
            IsOnTimeDelivery
        )
        SELECT
            O.OrderID,
            O.OrderNumber,
            CONVERT(int, CONVERT(char(8), O.OrderDate, 112)),
            CONVERT(int, CONVERT(char(8), O.RequiredDeliveryDate, 112)),
            CASE WHEN O.ShippedDate IS NULL THEN NULL ELSE CONVERT(int, CONVERT(char(8), O.ShippedDate, 112)) END,
            CASE WHEN O.DeliveredDate IS NULL THEN NULL ELSE CONVERT(int, CONVERT(char(8), O.DeliveredDate, 112)) END,
            C.CustomerKey,
            W.WarehouseKey,
            SC.SalesChannelKey,
            O.OrderStatus,
            O.ShipmentStatus,
            O.Carrier,
            O.PaymentTermsDays,
            O.LineCount,
            O.TotalQuantity,
            O.GrossOrderValue,
            O.NetOrderValue,
            O.CostAmount,
            O.GrossMarginAmount,
            O.ShippingCost,
            O.DeliveryDays,
            O.IsOnTimeDelivery
        FROM reporting.vw_OrderSummary O
        JOIN mart.DimCustomer C
            ON C.SourceCustomerID = O.CustomerID
        JOIN mart.DimWarehouse W
            ON W.SourceWarehouseID = O.WarehouseID
        JOIN mart.DimSalesChannel SC
            ON SC.SalesChannel = O.SalesChannel;

        INSERT mart.FactSalesLine
        (
            OrderItemKey,
            OrderKey,
            OrderNumber,
            LineNumber,
            OrderDateKey,
            CustomerKey,
            ProductKey,
            WarehouseKey,
            SalesChannelKey,
            OrderStatus,
            Quantity,
            UnitPrice,
            DiscountRate,
            UnitCost,
            GrossSalesAmount,
            NetSalesAmount,
            CostAmount,
            GrossMarginAmount,
            IsCompleted
        )
        SELECT
            L.OrderItemID,
            L.OrderID,
            L.OrderNumber,
            L.LineNumber,
            CONVERT(int, CONVERT(char(8), L.OrderDate, 112)),
            C.CustomerKey,
            P.ProductKey,
            W.WarehouseKey,
            SC.SalesChannelKey,
            L.OrderStatus,
            L.Quantity,
            L.UnitPrice,
            L.DiscountRate,
            L.UnitCost,
            L.LineGrossAmount,
            L.LineNetAmount,
            L.LineCostAmount,
            L.GrossMarginAmount,
            CASE WHEN L.OrderStatus = 'Completed' THEN 1 ELSE 0 END
        FROM reporting.vw_OrderLineDetails L
        JOIN mart.DimCustomer C
            ON C.SourceCustomerID = L.CustomerID
        JOIN mart.DimProduct P
            ON P.SourceProductID = L.ProductID
        JOIN mart.DimWarehouse W
            ON W.SourceWarehouseID = L.WarehouseID
        JOIN mart.DimSalesChannel SC
            ON SC.SalesChannel = L.SalesChannel;

        INSERT mart.FactReturn
        (
            ReturnKey,
            OrderKey,
            OrderItemKey,
            ReturnDateKey,
            OrderDateKey,
            CustomerKey,
            ProductKey,
            WarehouseKey,
            SalesChannelKey,
            ReturnStatus,
            ReturnReason,
            ReturnQuantity,
            RefundAmount,
            IsAcceptedReturn
        )
        SELECT
            R.ReturnID,
            O.OrderID,
            OI.OrderItemID,
            CONVERT(int, CONVERT(char(8), R.ReturnDate, 112)),
            CONVERT(int, CONVERT(char(8), O.OrderDate, 112)),
            C.CustomerKey,
            P.ProductKey,
            W.WarehouseKey,
            SC.SalesChannelKey,
            R.ReturnStatus,
            R.ReturnReason,
            R.ReturnQuantity,
            R.RefundAmount,
            CASE WHEN R.ReturnStatus IN ('Approved', 'Received') THEN 1 ELSE 0 END
        FROM sales.ProductReturn R
        JOIN sales.SalesOrderItem OI
            ON OI.OrderItemID = R.OrderItemID
        JOIN sales.SalesOrder O
            ON O.OrderID = OI.OrderID
        JOIN mart.DimCustomer C
            ON C.SourceCustomerID = O.CustomerID
        JOIN mart.DimProduct P
            ON P.SourceProductID = OI.ProductID
        JOIN mart.DimWarehouse W
            ON W.SourceWarehouseID = O.WarehouseID
        JOIN mart.DimSalesChannel SC
            ON SC.SalesChannel = O.SalesChannel;

        DECLARE @SnapshotDate date = EOMONTH((SELECT MAX(OrderDate) FROM sales.SalesOrder));

        INSERT mart.FactInventorySnapshot
        (
            SnapshotDateKey,
            ProductKey,
            WarehouseKey,
            QuantityOnHand,
            ReorderLevel,
            UnitsAboveReorderLevel,
            StockStatus
        )
        SELECT
            CONVERT(int, CONVERT(char(8), @SnapshotDate, 112)),
            P.ProductKey,
            W.WarehouseKey,
            I.QuantityOnHand,
            I.ReorderLevel,
            I.UnitsAboveReorderLevel,
            I.StockStatus
        FROM reporting.vw_InventoryStatus I
        JOIN mart.DimProduct P
            ON P.SourceProductID = I.ProductID
        JOIN mart.DimWarehouse W
            ON W.SourceWarehouseID = I.WarehouseID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

EXEC mart.usp_LoadReportingMart;
GO

PRINT 'Reporting mart loaded.';
GO
