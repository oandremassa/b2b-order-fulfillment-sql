# Reporting model

The operational tables remain normalised. The `mart` schema is a separate reporting layer used by the Power BI model.

## Dimensions

- `mart.DimDate`
- `mart.DimCustomer`
- `mart.DimProduct`
- `mart.DimWarehouse`
- `mart.DimSalesChannel`

## Facts

| Table | Grain |
|---|---|
| `mart.FactOrder` | One row per order |
| `mart.FactSalesLine` | One row per order item |
| `mart.FactReturn` | One row per return record |
| `mart.FactInventorySnapshot` | One row per product and warehouse at the snapshot date |

Relationships use single-direction filtering from dimensions to facts. Alternative order dates are present as inactive relationships in the semantic model.
