# 1.3 — ShopFlow

This chapter is the shared course example/data model.

## Source system
- customers
- products
- orders
- order_items

Important relationships:

```text
customers
    │
    │ customer_id
    ▼
orders
    │
    │ order_id
    ▼
order_items
    │
    │ product_id
    ▼
products
```

Important concept:
> `order_items` is the finest grain in the source system: one row = one product line within an order.

## Event stream
`order_events` contains events such as:
- placed
- paid
- shipped
- cancelled

## Analytics destination
Star schema:
- dim_customer
- dim_product
- dim_date
- dim_store
- fact_sales

`fact_sales` grain:
> One order line item.

## ShopFlow pipeline
```text
OLTP Source
    ↓
raw.*
    ↓
stg_*
    ↓
fact_sales / dimensions
    ↓
Dashboard / ML / Analytics
```

The same example is used throughout the course so data movement is easy to follow.
