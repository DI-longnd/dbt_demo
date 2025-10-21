{{
    config(
        materialized='table',
        engine='ReplacingMergeTree(inserted_at)',
        order_by='(customer_id, order_date, order_id)',
        settings={
            'index_granularity': '8192',
            'allow_nullable_key': 1
        }
    )
}}

-- Staging model for orders fact table
SELECT 
    order_id,
    customer_id,
    product_id,
    order_date,
    greatest(coalesce(quantity, 1), 1) as quantity,
    round(greatest(coalesce(total_amount, 0), 0), 2) as total_amount,
    -- Calculated fields
    round(
        greatest(coalesce(total_amount, 0), 0) / 
        greatest(coalesce(quantity, 1), 1), 
        2
    ) as unit_price,
    toYear(order_date) as year,
    toQuarter(order_date) as quarter,
    toMonth(order_date) as month,
    now() as inserted_at
FROM file('orders_first.parquet', 'Parquet')
WHERE order_id IS NOT NULL 
  AND customer_id IS NOT NULL 
  AND product_id IS NOT NULL
  AND order_date IS NOT NULL