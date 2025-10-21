{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='customer_id',
        settings={
            'index_granularity': '8192',
            'allow_nullable_key': 1
        }
    )
}}

-- Final mart: Customer Lifetime Value Analysis
-- This is what business users / dashboards will query
WITH customer_base AS (
    SELECT 
        customer_id,
        any(customer_name) as customer_name,
        any(customer_state) as customer_state,
        sum(order_count) as lifetime_orders,
        sum(total_quantity) as lifetime_quantity,
        sum(total_revenue) as total_revenue,
        sum(total_profit) as total_profit,
        round(avg(avg_order_value), 2) as avg_order_value,
        min(year_month) as first_purchase_date,
        max(year_month) as last_purchase_date,
        sum(unique_products_purchased) as total_unique_products,
        sum(unique_categories_purchased) as total_unique_categories
    FROM {{ ref('int_customer_monthly_metrics') }}
    GROUP BY customer_id
),

customer_metrics AS (
    SELECT 
        *,
        dateDiff('month', first_purchase_date, last_purchase_date) + 1 as customer_tenure_months
    FROM customer_base
),

max_date AS (
    SELECT max(last_purchase_date) as max_purchase_date
    FROM customer_metrics
)

SELECT 
    cm.*,
    CASE 
        WHEN cm.total_revenue >= 10000 THEN 'VIP'
        WHEN cm.total_revenue >= 5000 THEN 'High Value'
        WHEN cm.total_revenue >= 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END as customer_segment,
    dateDiff('month', cm.last_purchase_date, md.max_purchase_date) as months_since_last_purchase,
    CASE 
        WHEN dateDiff('month', cm.last_purchase_date, md.max_purchase_date) <= 3 THEN 'Active'
        WHEN dateDiff('month', cm.last_purchase_date, md.max_purchase_date) <= 6 THEN 'At Risk'
        ELSE 'Churned'
    END as customer_status
FROM customer_metrics cm
CROSS JOIN max_date md