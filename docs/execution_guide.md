# Execution guide

## Prerequisites

- SQL Server 2019 or later
- Windows Authentication enabled for your local user, or an equivalent SQL login
- `sqlcmd` installed, or SQL Server Management Studio
- Git for version control

## Option A: run with sqlcmd

Open PowerShell in the repository root and execute:

```powershell
sqlcmd `
  -S localhost `
  -E `
  -C `
  -b `
  -i ".\run_all.sql" `
  -v DatabaseName="B2BOrderAnalytics"
```

Parameter meaning:

- `-S localhost`: SQL Server instance
- `-E`: Windows Authentication
- `-C`: trust the local server certificate
- `-b`: return a failed process exit code when SQL Server reports an error
- `-i`: input script
- `-v`: SQLCMD variable used by the deployment scripts

For a named SQL Server instance, replace `localhost` with a value such as `localhost\SQLEXPRESS`.

## Option B: run with SQL Server Management Studio

1. Open `run_all.sql`.
2. Select **Query > SQLCMD Mode**.
3. Confirm that the working directory is the repository root.
4. Execute the script.

## Validate the installation

The build automatically executes `sql/07_tests/70_smoke_tests.sql`. A successful build ends with:

```text
All smoke tests passed.
Build completed successfully.
```

You can also inspect row counts:

```sql
USE B2BOrderAnalytics;

SELECT 'Customers' AS ObjectName, COUNT(*) AS RowCount FROM sales.Customer
UNION ALL
SELECT 'Products', COUNT(*) FROM inventory.Product
UNION ALL
SELECT 'Orders', COUNT(*) FROM sales.SalesOrder
UNION ALL
SELECT 'Order Items', COUNT(*) FROM sales.SalesOrderItem
UNION ALL
SELECT 'Stock Movements', COUNT(*) FROM inventory.StockMovement;
```

## Run the analysis pack

```powershell
sqlcmd `
  -S localhost `
  -d B2BOrderAnalytics `
  -E `
  -C `
  -b `
  -i ".\sql\06_analysis\60_business_questions.sql" `
  -W `
  -s "|"
```

## Profile the synthetic dataset

Run the companion profile after the main analysis pack:

```powershell
sqlcmd `
  -S localhost `
  -d B2BOrderAnalytics `
  -E `
  -C `
  -b `
  -i ".\sql\06_analysis\61_dataset_profile.sql" `
  -W `
  -s "|"
```

The profile should show a repeat-customer rate near 75%, visible differences between customer tiers and sales channels, and concentrated demand among the most popular products.

## Demonstrate a stored procedure

```sql
EXEC reporting.usp_GetSalesPerformance
    @StartDate = '2025-01-01',
    @EndDate = '2025-12-31',
    @CountryCode = 'DE';
```

```sql
EXEC reporting.usp_GetCustomerOrderHistory
    @CustomerID = 25;
```

## Demonstrate a controlled stock adjustment

Run the following inside a test database only:

```sql
EXEC inventory.usp_AdjustStock
    @ProductID = 1,
    @WarehouseID = 1,
    @QuantityChange = 25,
    @Reason = N'Cycle count correction';
```

The procedure writes an inventory movement and updates the current balance in one transaction.

## Run data quality checks manually

```sql
EXEC audit.usp_RunDataQualityChecks;

SELECT *
FROM audit.DataQualityRun
ORDER BY RunID DESC;

SELECT *
FROM audit.DataQualityResult
WHERE RunID = (SELECT MAX(RunID) FROM audit.DataQualityRun)
ORDER BY ResultID;
```

## Initialise Git

```powershell
git init
git add .
git commit -m "Build SQL Server order fulfillment analytics project"
```

Create an empty GitHub repository and then follow GitHub's commands to add the remote and push the `main` branch.

## Recommended evidence before publishing

1. Execute the full build locally.
2. Export the results of queries 1, 4, and 6 as CSV files.
3. Add one ERD screenshot or use the Mermaid diagram already included.
4. Add a screenshot showing that all smoke tests passed.
5. Review every script until you can explain the purpose of each section.
