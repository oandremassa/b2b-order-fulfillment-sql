USE [$(DatabaseName)];
GO

INSERT inventory.ProductCategory (CategoryName, Description)
VALUES
    (N'IT Accessories', N'Peripherals and accessories used in office IT environments.'),
    (N'Networking', N'Network connectivity and small infrastructure equipment.'),
    (N'Office Equipment', N'Equipment used in professional workspaces.'),
    (N'Storage Solutions', N'Physical and digital storage-related products.'),
    (N'Safety Equipment', N'Workplace safety and protection products.'),
    (N'Packaging Supplies', N'Packaging and shipping consumables.');
GO

INSERT inventory.Warehouse (WarehouseCode, WarehouseName, City, CountryCode)
VALUES
    ('MHM', N'Mannheim Distribution Centre', N'Mannheim', 'DE'),
    ('LEJ', N'Leipzig Fulfillment Hub', N'Leipzig', 'DE'),
    ('HAM', N'Hamburg Logistics Centre', N'Hamburg', 'DE');
GO

PRINT 'Reference data inserted.';
GO
