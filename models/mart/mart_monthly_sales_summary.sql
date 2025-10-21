{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='year_month',
        settings={
            'index_granularity': '8192',
            'allow_nullable_key': 1
        }
    )
}}

-- Final mart: Monthly Sales Performance
-- Track business performance over time
WITH monthly_base AS (
    SELECT 
        year_month,
        sum(order_count) as total_orders,
        sum(total_quantity) as total_quantity,
        sum(total_revenue) as total_revenue,
        sum(total_profit) as total_profit,
        uniq(customer_id) as unique_customers,
        sum(unique_products_purchased) as total_products_sold
    FROM {{ ref('int_customer_monthly_metrics') }}
    GROUP BY year_month
)

SELECT 
    year_month,
    total_orders,
    total_quantity,
    total_revenue,
    total_profit,
    round(total_profit / nullIf(total_revenue, 0) * 100, 2) as profit_margin_pct,
    unique_customers,
    round(total_revenue / nullIf(unique_customers, 0), 2) as revenue_per_customer,
    total_products_sold,
    round((total_revenue - lagInFrame(total_revenue, 1) OVER (ORDER BY year_month)) / 
          nullIf(lagInFrame(total_revenue, 1) OVER (ORDER BY year_month), 0) * 100, 2) as revenue_growth_pct,
    round((unique_customers - lagInFrame(unique_customers, 1) OVER (ORDER BY year_month)) / 
          nullIf(lagInFrame(unique_customers, 1) OVER (ORDER BY year_month), 0) * 100, 2) as customer_growth_pct
FROM monthly_base
ORDER BY year_month DESC