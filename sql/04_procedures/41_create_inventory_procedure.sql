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

CREATE PROCEDURE inventory.usp_AdjustStock
    @ProductID int,
    @WarehouseID int,
    @QuantityChange int,
    @Reason nvarchar(200),
    @MovementDate datetime2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @QuantityChange = 0
        THROW 51010, 'QuantityChange must be different from zero.', 1;

    IF NULLIF(LTRIM(RTRIM(@Reason)), N'') IS NULL
        THROW 51011, 'Reason is required.', 1;

    IF NOT EXISTS (SELECT 1 FROM inventory.Product WHERE ProductID = @ProductID)
        THROW 51012, 'ProductID does not exist.', 1;

    IF NOT EXISTS (SELECT 1 FROM inventory.Warehouse WHERE WarehouseID = @WarehouseID)
        THROW 51013, 'WarehouseID does not exist.', 1;

    SET @MovementDate = COALESCE(@MovementDate, SYSUTCDATETIME());

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentQuantity int;
        DECLARE @NewQuantity int;

        SELECT @CurrentQuantity = QuantityOnHand
        FROM inventory.StockBalance WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductID = @ProductID
          AND WarehouseID = @WarehouseID;

        IF @CurrentQuantity IS NULL
            THROW 51014, 'Stock balance does not exist for the product and warehouse.', 1;

        SET @NewQuantity = @CurrentQuantity + @QuantityChange;

        IF @NewQuantity < 0
            THROW 51015, 'Adjustment would create a negative stock balance.', 1;

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
        VALUES
        (
            @ProductID,
            @WarehouseID,
            @MovementDate,
            'Adjustment',
            @QuantityChange,
            'ManualAdjustment',
            NULL,
            @Reason
        );

        UPDATE inventory.StockBalance
        SET QuantityOnHand = @NewQuantity,
            LastUpdated = SYSUTCDATETIME()
        WHERE ProductID = @ProductID
          AND WarehouseID = @WarehouseID;

        COMMIT TRANSACTION;

        SELECT
            @ProductID AS ProductID,
            @WarehouseID AS WarehouseID,
            @CurrentQuantity AS PreviousQuantity,
            @QuantityChange AS QuantityChange,
            @NewQuantity AS NewQuantity,
            @MovementDate AS MovementDate,
            @Reason AS Reason;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

PRINT 'Inventory adjustment procedure created.';
GO
