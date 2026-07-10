# B2B Order Fulfillment & Inventory Analytics

A SQL Server portfolio project that models and analyses the order-to-delivery process of a fictional B2B distributor operating across Germany and nearby European markets.

The project is designed for **Junior Data Analyst**, **BI Working Student**, and **Junior SQL/Reporting** applications. It demonstrates strong SQL fundamentals, relational modelling, business-oriented analysis, reusable database objects, and data quality controls without relying on unnecessarily advanced engineering patterns.

## Business scenario

The fictional company sells professional equipment to business customers through online, partner, and sales-representative channels. Management needs reliable answers to questions such as:

- How are revenue and gross margin developing month over month?
- Which products and customer segments generate the most value?
- Which warehouses deliver orders on time?
- Which product categories have the highest return rates?
- Which products require replenishment?
- Are operational records internally consistent?

## What this project demonstrates

- SQL Server and T-SQL
- Relational data modelling and normalisation
- Primary keys, foreign keys, unique constraints, check constraints, and defaults
- Deterministic synthetic data generation in SQL
- Joins, CTEs, aggregations, window functions, ranking, and conditional logic
- Reporting views
- Parameterised stored procedures
- Transaction handling and error handling
- Index design for common access patterns
- Automated data quality checks
- Smoke tests and reproducible database deployment
- Technical documentation for GitHub

## Technology

- Microsoft SQL Server 2019 or later
- T-SQL
- `sqlcmd` or SQL Server Management Studio with SQLCMD Mode
- Git and GitHub

## Repository structure

```text
b2b-order-fulfillment-sql/
├── README.md
├── LICENSE
├── run_all.sql
├── docs/
│   ├── business_rules.md
│   ├── data_dictionary.md
│   ├── erd.md
│   ├── execution_guide.md
│   ├── implementation_roadmap.md
│   ├── interview_guide.md
│   └── synthetic_data_design.md
├── outputs/
│   └── .gitkeep
└── sql/
    ├── 00_setup/
    ├── 01_ddl/
    ├── 02_seed/
    ├── 03_views/
    ├── 04_procedures/
    ├── 05_quality/
    ├── 06_analysis/
    └── 07_tests/
```

## Data model

The operational model uses separate schemas for clear responsibility:

- `sales`: customers, orders, order items, shipments, and returns
- `inventory`: product master data, warehouses, stock movements, and balances
- `reporting`: reusable analytical views and reporting procedures
- `audit`: data quality runs and results

See [`docs/erd.md`](docs/erd.md) for the Mermaid entity-relationship diagram and [`docs/data_dictionary.md`](docs/data_dictionary.md) for field-level documentation.

## Synthetic dataset

The build generates approximately:

- 400 customers, including purchasing customers, one-time buyers, prospects, and inactive accounts
- 90 products across 6 categories
- 3 warehouses
- 5,000 sales orders
- approximately 15,000 order lines
- a repeat-customer rate close to 75%
- weighted demand by customer tier, sales channel, and product popularity
- shipments for fulfilled orders
- category-sensitive returns for a controlled subset of delivered order lines
- opening stock, receipts, sales, returns, and adjustment movements

The data is fully synthetic. Customer email addresses use the reserved `.test` domain. See [`docs/synthetic_data_design.md`](docs/synthetic_data_design.md) for the generation rules and their business rationale.

## Quick start with sqlcmd

Run the command from the repository root:

```powershell
sqlcmd `
  -S localhost `
  -E `
  -C `
  -b `
  -i ".\run_all.sql" `
  -v DatabaseName="B2BOrderAnalytics"
```

The script intentionally rebuilds the database from scratch to make the project reproducible. Do not point it at a database that contains data you need.

After the build, run the analytical query pack:

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

Detailed instructions are available in [`docs/execution_guide.md`](docs/execution_guide.md).

## Main reporting objects

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

## Analytical query pack

The file [`sql/06_analysis/60_business_questions.sql`](sql/06_analysis/60_business_questions.sql) contains portfolio-ready analyses covering:

1. Monthly revenue and month-over-month growth
2. Product revenue and gross-margin ranking
3. Customer value quartiles
4. Warehouse delivery performance
5. Product-category return rates
6. Inventory replenishment priorities
7. Customer revenue concentration
8. Sales-channel performance
9. Repeat-customer behaviour
10. Latest data quality results

The companion file [`sql/06_analysis/61_dataset_profile.sql`](sql/06_analysis/61_dataset_profile.sql) validates that customer, channel, and product demand distributions are plausible rather than perfectly uniform.

## Design decisions

- The project uses a normalised operational model rather than a star schema because its main goal is to demonstrate relational SQL foundations.
- Order totals are calculated from order lines instead of being duplicated in the order header.
- Stock movements are treated as the auditable source of inventory change; the balance table provides fast access to current stock.
- Synthetic data generation is deterministic so repeated builds produce the same logical dataset. Customer demand uses transparent long-tail rules instead of uniform random assignment.
- Triggers, dynamic SQL, partitioning, CDC, and orchestration tools are deliberately out of scope. These would add complexity without improving the junior-level learning objective.

## Suggested GitHub evidence

Add the following items after executing the project locally:

- A screenshot of the database diagram or Mermaid ERD
- A screenshot of the smoke-test output
- CSV exports of two or three analytical queries in `outputs/`
- A short project walkthrough in the repository description
- Optional: a Power BI report connected to the reporting views as a later extension

## Interview positioning

This project should be presented as evidence that you can:

- translate business questions into a relational model;
- create reliable tables and constraints;
- generate and validate test data;
- write readable analytical SQL;
- package logic into views and stored procedures;
- check data quality systematically;
- document and deploy a database project reproducibly.

Follow [`docs/implementation_roadmap.md`](docs/implementation_roadmap.md) to study the project in a defensible order, then use [`docs/interview_guide.md`](docs/interview_guide.md) to prepare concise explanations for each technical decision.

## Licence

MIT Licence. The company, customers, products, transactions, and business scenario are fictional.
