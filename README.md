# B2B Order Fulfillment & Inventory Analytics

SQL Server database for a B2B distributor's order-to-delivery process. The project covers customer orders, shipments, returns, stock movements and a small reporting layer built with T-SQL.

All records are synthetic. The database can be rebuilt from scratch and produces the same dataset on every run.

## Scope

| Area | Included |
|---|---|
| Operational model | Customers, products, orders, order lines, shipments and returns |
| Inventory | Warehouses, stock movements and current balances |
| Reporting | Reusable views and parameterised stored procedures |
| Data quality | Ten checks with persisted run history |
| Test data | Deterministic T-SQL generation for 400 customers and 5,000 orders |
| Validation | Fail-fast deployment and smoke tests |

## Data model

The database is split into four schemas:

- `sales` — customers, orders, shipments and returns
- `inventory` — products, warehouses, movements and balances
- `reporting` — analytical views and reporting procedures
- `audit` — data quality runs and results

The operational model is normalised. Order values are derived from order lines, while inventory movements provide the audit trail behind each current balance.

See the [ERD](docs/erd.md) and [data dictionary](docs/data_dictionary.md) for the full model.

## Build

Requirements:

- SQL Server 2019 or later
- `sqlcmd` or SQL Server Management Studio with SQLCMD Mode

From the repository root:

```powershell
sqlcmd `
  -S localhost `
  -E `
  -C `
  -b `
  -i ".\run_all.sql" `
  -v DatabaseName="B2BOrderAnalytics"
```

The script drops and recreates `B2BOrderAnalytics`. A successful run ends with:

```text
All smoke tests passed.
Build completed successfully.
```

Run the analysis scripts after the build:

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

More commands are available in the [execution guide](docs/execution_guide.md).

## Reporting objects

### Views

- `reporting.vw_OrderLineDetails`
- `reporting.vw_OrderSummary`
- `reporting.vw_MonthlySales`
- `reporting.vw_CustomerMetrics`
- `reporting.vw_ProductPerformance`
- `reporting.vw_InventoryStatus`
- `reporting.vw_FulfillmentPerformance`

### Stored procedures

- `reporting.usp_GetSalesPerformance`
- `reporting.usp_GetCustomerOrderHistory`
- `inventory.usp_AdjustStock`
- `audit.usp_RunDataQualityChecks`

## Analysis included

The main query pack answers ten questions:

1. How is monthly revenue changing?
2. Which products lead revenue and gross margin?
3. Which customers account for the most value?
4. How does delivery performance vary by warehouse?
5. Which categories have the highest return rates?
6. Which products require replenishment?
7. How concentrated is revenue among the top customers?
8. How do sales channels compare?
9. How many customers place repeat orders?
10. Did the latest data quality run pass?

The companion dataset profile checks customer participation, order frequency, channel mix and product-demand concentration.

## Example results

A deterministic build produced:

- 400 customers, with 320 placing at least one order
- 237 repeat customers and 83 one-time customers
- 74.06% repeat-customer rate
- 43.96% of sold units concentrated in the 15 most popular products
- 10 data quality checks passed, with no failures

Enterprise accounts represented 32.96% of completed orders but 58.89% of net revenue. Online sales had the highest gross-margin rate, while partner orders had a higher average value but a lower margin rate.

See [results.md](docs/results.md) for the supporting figures.

## Repository layout

```text
.
├── docs/
│   ├── business_rules.md
│   ├── data_dictionary.md
│   ├── data_generation.md
│   ├── erd.md
│   ├── execution_guide.md
│   └── results.md
├── outputs/
├── sql/
│   ├── 00_setup/
│   ├── 01_ddl/
│   ├── 02_seed/
│   ├── 03_views/
│   ├── 04_procedures/
│   ├── 05_quality/
│   ├── 06_analysis/
│   └── 07_tests/
├── run_all.sql
└── README.md
```

## Current limitations

- One shipment per order
- One currency and no tax calculation
- No partial fulfillment or backorder workflow
- Current stock is maintained alongside the movement ledger
- Data is generated for analysis and testing, not copied from a live system

## Licence

MIT Licence.

## Power BI report

The `powerbi/` directory contains a Power BI Project connected to the dimensional reporting layer in the `mart` schema.

The report is organised into three pages:

- `Executive Overview` - revenue, customer mix, channel economics, fulfillment and inventory alerts
- `Fulfillment & Returns` - delivery reliability, warehouse performance, carriers and return drivers
- `Inventory & Products` - stock health, product demand and replenishment priorities

Open the project after rebuilding the database:

```text
powerbi/B2BOrderAnalytics.pbip
```

The report connects to `localhost` and the `B2BOrderAnalytics` database using Windows authentication.
