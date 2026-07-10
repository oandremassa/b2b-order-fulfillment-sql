# Data generation

The seed scripts create a deterministic dataset: rebuilding the database produces the same records and analytical results.

The objective is not to reproduce every detail of a distribution business. The rules create enough variation to test joins, aggregations, reporting logic and operational controls without relying on an external data generator.

## Customers

The 400 customers are grouped into three commercial types:

| Customer range | Type | Order pattern |
|---|---|---|
| 1-40 | Enterprise | Frequent orders with more lines and larger quantities |
| 41-150 | MidMarket | Regular orders with moderate size |
| 151-400 | SMB | Smaller and less frequent orders |

Customers 1-320 place at least one order. Customers 1-240 receive repeat demand, while the remaining accounts represent one-time buyers or customers without an order in the generated period.

After the first order is assigned, additional demand follows a long-tail distribution:

- 35% to the first 40 accounts
- 40% to accounts 41-140
- 25% to accounts 141-240

## Sales channels and discounts

Channel selection depends on customer type:

- Enterprise accounts mainly use sales representatives and partners.
- Mid-market accounts use all three channels.
- SMB accounts primarily order online.

Partner orders receive larger discounts on average. Sales-representative orders use negotiated discounts, while online orders generally receive lower discounts.

## Products and quantities

Product selection uses three popularity bands:

- about 45% of order lines use the first 15 products;
- about 35% use the next 30 products;
- about 20% use the remaining 45 products.

Order line count and quantity also vary by customer type, so enterprise orders are normally larger than SMB orders.

## Warehouses

Warehouse assignment uses a simplified geographic rule:

- Hamburg and Amsterdam customers are served from Hamburg;
- Berlin and Leipzig customers are served from Leipzig;
- other locations are served from Mannheim.

## Shipments and returns

Delivered dates are generated from the shipment date and warehouse service pattern. Return probability varies by product category and increases for late deliveries.

Most returns contain one unit. Refund amounts are only recorded after a return is approved or received.

## Validation

`sql/06_analysis/61_dataset_profile.sql` reports:

- purchasing, one-time, repeat and non-purchasing customers;
- order share by customer type;
- sales-channel mix;
- demand concentration among popular products;
- minimum, average and maximum order counts by customer type.

The smoke tests also check that customer participation and repeat-order behaviour remain within the expected ranges.
