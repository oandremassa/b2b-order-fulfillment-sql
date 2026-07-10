# Results from a local build

The figures below were produced by rebuilding the database locally and running `sql/06_analysis/61_dataset_profile.sql`.

## Customer activity

| Metric | Value |
|---|---:|
| Total customers | 400 |
| Customers with at least one order | 320 |
| One-time customers | 83 |
| Repeat customers | 237 |
| Customers without orders | 80 |
| Repeat-customer rate | 74.06% |

## Customer types

| Customer type | Completed orders | Order share | Average order value | Net revenue |
|---|---:|---:|---:|---:|
| Enterprise | 1,549 | 32.96% | 12,565.09 | 19,463,329.95 |
| MidMarket | 1,997 | 42.49% | 5,748.32 | 11,479,404.85 |
| SMB | 1,154 | 24.55% | 1,826.77 | 2,108,087.61 |

Enterprise customers generated 58.89% of net revenue from 32.96% of completed orders.

## Sales channels

| Sales channel | Completed orders | Order share | Net revenue | Average order value | Gross-margin rate |
|---|---:|---:|---:|---:|---:|
| SalesRep | 1,934 | 41.15% | 16,253,950.16 | 8,404.32 | 22.54% |
| Online | 1,549 | 32.96% | 7,469,016.81 | 4,821.83 | 27.25% |
| Partner | 1,217 | 25.89% | 9,327,855.44 | 7,664.63 | 18.49% |

Online orders produced the highest gross-margin rate. Partner orders had a higher average order value but a lower margin rate because their generated discount range is higher.

## Product concentration

| Metric | Value |
|---|---:|
| Units sold from the 15 most popular products | 86,177 |
| Total units sold | 196,036 |
| Top-15 unit share | 43.96% |

## Order frequency

| Customer type | Minimum orders | Average orders | Maximum orders |
|---|---:|---:|---:|
| Enterprise | 5 | 39.55 | 105 |
| MidMarket | 2 | 18.36 | 73 |
| SMB | 0 | 4.70 | 52 |

The minimum includes registered customers that did not place an order during the generated period.

## Data quality

| Checks passed | Checks failed | Status |
|---:|---:|---|
| 10 | 0 | PASS |

The checks cover duplicate business keys, orphan records, shipment chronology, return quantities, inventory reconciliation, negative stock and order-status consistency.
