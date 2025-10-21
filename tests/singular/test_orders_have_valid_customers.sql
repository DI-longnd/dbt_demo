-- Test that all orders have valid customer references
-- This is a singular test (specific to this business logic)

SELECT 
    o.order_id,
    o.customer_id
FROM {{ ref('stg_orders') }} o
LEFT JOIN {{ ref('stg_customers') }} c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL