# Synthetic Data Design

The dataset is deterministic: rebuilding the database produces the same logical records and the same analytical results. This makes testing, documentation, and interview demonstrations reproducible.

The generator is not intended to simulate every detail of a real distributor. It creates a controlled B2B scenario with enough variation to support meaningful SQL analysis.

## Customer portfolio

The 400 customers are divided into three commercial tiers:

| Customer range | Type | Intended behaviour |
|---|---|---|
| 1-40 | Enterprise | Small strategic group with high repeat demand and larger orders |
| 41-150 | MidMarket | Regular accounts with moderate-to-high purchasing frequency |
| 151-400 | SMB | Larger population with smaller and less frequent orders |

Customers 1-320 receive at least one order. Customers 1-240 form the repeat-purchase base. The remaining customers represent one-time buyers, prospects, or inactive accounts.

This produces a repeat-customer rate close to 75%, rather than assigning the same number of orders to every customer.

## Repeat-demand weighting

After the first order is assigned to each purchasing customer, additional orders are distributed with a long-tail pattern:

- 35% to the first 40 strategic accounts;
- 40% to customers 41-140;
- 25% to customers 141-240.

The rule is intentionally readable T-SQL. It demonstrates business-oriented synthetic data design without requiring an external data-generation framework.

## Sales channels

Channel assignment depends on customer type:

- Enterprise customers primarily use sales representatives and partners.
- Mid-market customers use a mixed channel model.
- SMB customers primarily order online.

Discounts also depend on the channel. Partner orders normally receive the highest discounts, sales-representative orders receive negotiated discounts, and online orders have fewer discounts. This creates visible differences in average order value and gross-margin rate.

## Products and quantities

Product demand follows a simple popularity distribution:

- approximately 45% of order lines select from the first 15 products;
- approximately 35% select from the next 30 products;
- approximately 20% select from the remaining 45 products.

Order quantity and line count depend on customer type. Enterprise orders are larger and contain more lines than SMB orders.

## Warehouses

Warehouse assignment follows a basic geographic rule:

- Hamburg and Amsterdam customers are served from Hamburg;
- Berlin and Leipzig customers are served from Leipzig;
- other locations are served from Mannheim.

The model is deliberately simplified, but it provides a defensible reason for warehouse-level performance analysis.

## Returns

Return probability varies by product category and increases when a delivery is late. Most returns contain one unit. Refunds are recorded only after the return is approved or received.

## Validation

The file `sql/06_analysis/61_dataset_profile.sql` profiles:

- purchasing, one-time, repeat, and non-purchasing customers;
- order share by customer type;
- sales-channel mix;
- concentration among the most popular products;
- minimum, average, and maximum orders by customer type.

Smoke tests also verify that customer participation and repeat behaviour remain inside expected ranges.
