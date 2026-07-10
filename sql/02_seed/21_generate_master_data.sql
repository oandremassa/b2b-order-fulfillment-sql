USE [$(DatabaseName)];
GO
SET NOCOUNT ON;

;WITH
E1(N) AS
(
    SELECT 1
    FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) AS D(N)
),
E2(N) AS (SELECT 1 FROM E1 A CROSS JOIN E1 B),
E4(N) AS (SELECT 1 FROM E2 A CROSS JOIN E2 B),
Numbers AS
(
    SELECT TOP (400)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM E4
),
CustomerSeeds AS
(
    SELECT
        N,
        ABS(CONVERT(bigint, CHECKSUM(CONCAT('customer-', N)))) AS Seed
    FROM Numbers
),
CustomerAttributes AS
(
    SELECT
        N,
        Seed,
        CASE
            WHEN Seed % 100 < 68 THEN 'DE'
            WHEN Seed % 100 < 80 THEN 'AT'
            WHEN Seed % 100 < 90 THEN 'CH'
            ELSE 'NL'
        END AS CountryCode
    FROM CustomerSeeds
)
INSERT sales.Customer
(
    CustomerNumber,
    CustomerName,
    CustomerType,
    Industry,
    Email,
    CountryCode,
    City,
    RegistrationDate,
    IsActive
)
SELECT
    CONCAT('C', RIGHT('000000' + CONVERT(varchar(6), N), 6)),
    CONCAT(
        CASE Seed % 8
            WHEN 0 THEN N'Adler'
            WHEN 1 THEN N'Bergmann'
            WHEN 2 THEN N'Kronen'
            WHEN 3 THEN N'Neumann'
            WHEN 4 THEN N'Rheinland'
            WHEN 5 THEN N'Steinwerk'
            WHEN 6 THEN N'Nordlicht'
            ELSE N'Westfalen'
        END,
        N' ',
        CASE Seed % 6
            WHEN 0 THEN N'Systems'
            WHEN 1 THEN N'Trading'
            WHEN 2 THEN N'Services'
            WHEN 3 THEN N'Solutions'
            WHEN 4 THEN N'Group'
            ELSE N'Partners'
        END,
        N' ', RIGHT('000' + CONVERT(varchar(3), N), 3)
    ),
    CASE
        WHEN N <= 40 THEN 'Enterprise'
        WHEN N <= 150 THEN 'MidMarket'
        ELSE 'SMB'
    END,
    CASE Seed % 7
        WHEN 0 THEN 'Manufacturing'
        WHEN 1 THEN 'Retail'
        WHEN 2 THEN 'Professional Services'
        WHEN 3 THEN 'Healthcare'
        WHEN 4 THEN 'Technology'
        WHEN 5 THEN 'Construction'
        ELSE 'Hospitality'
    END,
    CONCAT('contact', RIGHT('0000' + CONVERT(varchar(4), N), 4), '@example.test'),
    CountryCode,
    CASE CountryCode
        WHEN 'DE' THEN
            CASE Seed % 9
                WHEN 0 THEN N'Berlin'
                WHEN 1 THEN N'Hamburg'
                WHEN 2 THEN N'Munich'
                WHEN 3 THEN N'Cologne'
                WHEN 4 THEN N'Frankfurt'
                WHEN 5 THEN N'Stuttgart'
                WHEN 6 THEN N'Düsseldorf'
                WHEN 7 THEN N'Leipzig'
                ELSE N'Mannheim'
            END
        WHEN 'AT' THEN CASE Seed % 2 WHEN 0 THEN N'Vienna' ELSE N'Graz' END
        WHEN 'CH' THEN CASE Seed % 2 WHEN 0 THEN N'Zurich' ELSE N'Basel' END
        ELSE CASE Seed % 2 WHEN 0 THEN N'Amsterdam' ELSE N'Rotterdam' END
    END,
    DATEADD(DAY, -CONVERT(int, Seed % 1000), CONVERT(date, '2024-01-01')),
    CASE WHEN N <= 360 THEN 1 ELSE 0 END
FROM CustomerAttributes;
GO

;WITH
E1(N) AS
(
    SELECT 1
    FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) AS D(N)
),
E2(N) AS (SELECT 1 FROM E1 A CROSS JOIN E1 B),
Numbers AS
(
    SELECT TOP (90)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM E2
),
ProductSeeds AS
(
    SELECT
        N,
        1 + ((N - 1) % 6) AS CategoryOrdinal,
        ABS(CONVERT(bigint, CHECKSUM(CONCAT('product-', N)))) AS Seed
    FROM Numbers
),
ProductCosts AS
(
    SELECT
        N,
        CategoryOrdinal,
        Seed,
        CAST(12.00 + (Seed % 24000) / 100.0 AS decimal(12,2)) AS StandardCost
    FROM ProductSeeds
)
INSERT inventory.Product
(
    ProductCategoryID,
    SKU,
    ProductName,
    StandardCost,
    ListPrice,
    ReorderLevel,
    IsActive
)
SELECT
    C.ProductCategoryID,
    CONCAT('PRD-', RIGHT('0000' + CONVERT(varchar(4), PC.N), 4)),
    CONCAT(C.CategoryName, N' Item ', RIGHT('000' + CONVERT(varchar(3), PC.N), 3)),
    PC.StandardCost,
    CAST(ROUND(PC.StandardCost * (1.28 + (PC.Seed % 23) / 100.0), 2) AS decimal(12,2)),
    80 + CONVERT(int, PC.Seed % 221),
    1
FROM ProductCosts PC
JOIN inventory.ProductCategory C
  ON C.CategoryName =
     CASE PC.CategoryOrdinal
         WHEN 1 THEN N'IT Accessories'
         WHEN 2 THEN N'Networking'
         WHEN 3 THEN N'Office Equipment'
         WHEN 4 THEN N'Storage Solutions'
         WHEN 5 THEN N'Safety Equipment'
         ELSE N'Packaging Supplies'
     END;
GO

PRINT 'Customers and products generated.';
GO
