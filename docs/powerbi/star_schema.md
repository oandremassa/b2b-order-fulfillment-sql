# Star schema

```mermaid
erDiagram
    DimDate ||--o{ FactOrder : order_date
    DimCustomer ||--o{ FactOrder : customer
    DimWarehouse ||--o{ FactOrder : warehouse
    DimSalesChannel ||--o{ FactOrder : channel

    DimDate ||--o{ FactSalesLine : order_date
    DimCustomer ||--o{ FactSalesLine : customer
    DimProduct ||--o{ FactSalesLine : product
    DimWarehouse ||--o{ FactSalesLine : warehouse
    DimSalesChannel ||--o{ FactSalesLine : channel

    DimDate ||--o{ FactReturn : order_date
    DimCustomer ||--o{ FactReturn : customer
    DimProduct ||--o{ FactReturn : product
    DimWarehouse ||--o{ FactReturn : warehouse
    DimSalesChannel ||--o{ FactReturn : channel

    DimDate ||--o{ FactInventorySnapshot : snapshot_date
    DimProduct ||--o{ FactInventorySnapshot : product
    DimWarehouse ||--o{ FactInventorySnapshot : warehouse
```

`FactOrder` also contains required, shipped and delivered date keys. Those relationships are inactive in the semantic model and can be used explicitly when a measure needs another date role.

Returns use the original order date as the active reporting date. The return date remains available as an inactive relationship.
