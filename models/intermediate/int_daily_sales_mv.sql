{{
    config(
        materialized='materialized_view',
        engine='SummingMergeTree()',
        order_by='(order_date, product_id)',
        settings={
            'index_granularity': '8192',
            'allow_nullable_key': 1
        },
        to_table='daily_sales_summary'
    )
}}

-- Materialized View: Automatically updates when new data inserted
-- This aggregates daily sales in real-time

SELECT 
    toDate(order_date) as order_date,
    product_id,
    customer_state,
    
    -- Aggregated metrics
    count() as order_count,
    sum(quantity) as total_quantity,
    sum(total_amount) as total_revenue,
    {{ calculate_profit('sum(total_amount)', 30) }} as total_profit,
    
    -- Pre-calculated averages
    round(avg(total_amount), 2) as avg_order_value,
    uniq(customer_id) as unique_customers

FROM {{ ref('int_orders_enriched') }}
GROUP BY 
    order_date,
    product_id,
    customer_state