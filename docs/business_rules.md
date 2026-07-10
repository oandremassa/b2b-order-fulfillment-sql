# Business rules

## Customer rules

1. Every customer has a unique customer number and email address.
2. Customer type must be `SMB`, `MidMarket`, or `Enterprise`.
3. Registration date cannot be later than the current date.
4. Synthetic email addresses use the `.test` domain.

## Product rules

1. Every product belongs to one product category.
2. SKU is unique.
3. Standard cost cannot be negative.
4. List price must be greater than zero.
5. Reorder level cannot be negative.

## Order rules

1. Every order belongs to one customer and one fulfillment warehouse.
2. Required delivery date cannot be earlier than order date.
3. Order status must be `Pending`, `Processing`, `Shipped`, `Completed`, or `Cancelled`.
4. Sales channel must be `Online`, `SalesRep`, or `Partner`.
5. Payment terms must be between 0 and 90 days.
6. A cancelled order should contain a cancellation reason.
7. Order totals are derived from order lines and are not stored in the order header.

## Order-line rules

1. Each line number is unique within its order.
2. Quantity must be greater than zero.
3. Unit price must be greater than zero.
4. Unit cost cannot be negative.
5. Discount rate must be between 0% and 30%.
6. Gross, net, and cost amounts are persisted computed columns.

## Shipment rules

1. The current scope permits at most one shipment per order.
2. Shipment status must be `Preparing`, `InTransit`, `Delivered`, or `Cancelled`.
3. Delivered date cannot be earlier than shipped date.
4. A completed order should have a delivered shipment.
5. A cancelled order should not have an active shipment.

## Return rules

1. A return references a specific order line.
2. Returned quantity must be positive and cannot exceed ordered quantity.
3. Return status must be `Requested`, `Approved`, `Received`, or `Rejected`.
4. Return reason must be one of the defined business values.
5. Rejected returns have no refund amount.

## Inventory rules

1. Inventory is tracked at product-and-warehouse level.
2. Every movement has a non-zero signed quantity.
3. Sales create negative movements; receipts and accepted returns create positive movements.
4. Current stock balance should equal the sum of all stock movements.
5. The stock adjustment procedure prevents a negative resulting balance.

## Data quality rules

The automated quality procedure checks:

- duplicate customer emails;
- duplicate product SKUs;
- orphan order items;
- invalid shipment chronology;
- returned quantity greater than ordered quantity;
- stock balance mismatches;
- negative stock;
- completed orders without delivered shipments;
- cancelled orders with shipments;
- orders without order lines.

## Synthetic demand rules

1. The first 320 customers receive at least one order.
2. Customers 1-240 form the repeat-purchase base.
3. Repeat demand is weighted toward enterprise and mid-market customers.
4. Sales channel depends on customer type.
5. Warehouse assignment follows a simplified geographic rule.
6. Product demand is concentrated among a popular-product group.
7. Return probability varies by product category and late-delivery status.
8. Refund amount is recognised only for approved or received returns.

See `docs/data_generation.md` for the complete rationale.
