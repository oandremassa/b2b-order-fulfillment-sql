# Execution guide

## Requirements

- SQL Server 2019 or later
- Windows Authentication or a valid SQL login
- `sqlcmd`, or SQL Server Management Studio with SQLCMD Mode

## Build with sqlcmd

Open PowerShell in the repository root:

```powershell
sqlcmd `
  -S localhost `
  -E `
  -C `
  -b `
  -i ".\run_all.sql" `
  -v DatabaseName="B2BOrderAnalytics"
```

For a named instance, replace `localhost` with a value such as `localhost\SQLEXPRESS`.

The command uses:

- `-E` for Windows Authentication
- `-C` to trust the local certificate
- `-b` to return a non-zero exit code when SQL Server reports an error
- `-i` for the input script
- `-v` for the SQLCMD database-name variable

`run_all.sql` drops and recreates the target database.

## Build with SQL Server Management Studio

1. Open `run_all.sql`.
2. Enable **Query > SQLCMD Mode**.
3. Set the working directory to the repository root.
4. Execute the script.

## Expected result

The deployment runs the smoke tests automatically. A successful build ends with:

```text
All smoke tests passed.
Build completed successfully.
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

## Run the dataset profile

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

## Save local output

```powershell
sqlcmd `
  -S localhost `
  -d B2BOrderAnalytics `
  -E `
  -C `
  -b `
  -i ".\sql\06_analysis\60_business_questions.sql" `
  -o ".\outputs\business_analysis.txt" `
  -W `
  -s "|"
```

Files created under `outputs/` are ignored by Git by default.

## Stored procedure examples

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

## Stock adjustment example

Run against the generated database only:

```sql
EXEC inventory.usp_AdjustStock
    @ProductID = 1,
    @WarehouseID = 1,
    @QuantityChange = 25,
    @Reason = N'Cycle count correction';
```

The procedure inserts a stock movement and updates the current balance in the same transaction.

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
