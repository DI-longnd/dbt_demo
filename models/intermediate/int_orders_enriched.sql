{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='(order_date, order_id)',
        settings={
            'index_granularity': '8192',
            'allow_nullable_key': 1
        }
    )
}}

-- Enrich orders with customer and product information
-- Using macros for reusable business logic
SELECT 
    o.order_id as order_id, 
    o.order_date as order_date,
    {{ get_date_parts('o.order_date') }},
    
    -- Customer info
    o.customer_id as customer_id,
    c.full_name as customer_name,
    c.email as customer_email,
    c.city as customer_city,
    c.state as customer_state,
    
    -- Product info
    o.product_id as product_id,
    p.product_name as product_name,
    p.category as product_category,
    p.brand as product_brand,
    
    -- Order metrics
    o.quantity,
    o.unit_price,
    o.total_amount,
    
    -- Profit calculation using macro
    {{ calculate_profit('o.total_amount', 30) }} as profit_amount
    
FROM {{ ref('stg_orders') }} o
LEFT JOIN {{ ref('stg_customers') }} c 
    ON o.customer_id = c.customer_id
LEFT JOIN {{ ref('stg_products') }} p 
    ON o.product_id = p.product_id