{{
    config(
        materialized='table',
        engine='SummingMergeTree()',
        order_by='(year_month, customer_id)',
        settings={
            'index_granularity': '8192',
            'allow_nullable_key': 1
        }
    )
}}

-- Aggregate customer metrics by month
-- This intermediate model prepares data for mart layer
SELECT 
    toStartOfMonth(order_date) as year_month,
    customer_id,
    any(customer_name) as customer_name,
    any(customer_state) as customer_state,
    
    -- Aggregated metrics
    count() as order_count,
    sum(quantity) as total_quantity,
    sum(total_amount) as total_revenue,
    sum(profit_amount) as total_profit,
    
    -- Calculated KPIs
    round(avg(total_amount), 2) as avg_order_value,
    uniq(product_id) as unique_products_purchased,
    uniq(product_category) as unique_categories_purchased

FROM {{ ref('int_orders_enriched') }}
GROUP BY 
    year_month,
    customer_id