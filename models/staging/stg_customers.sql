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

-- Staging model for customers dimension
SELECT 
    customer_id,
    coalesce(first_name, '') as first_name,
    coalesce(last_name, '') as last_name,
    coalesce(email, '') as email,
    coalesce(city, 'Unknown') as city,
    coalesce(state, 'Unknown') as state,
    concat(coalesce(first_name, ''), ' ', coalesce(last_name, '')) as full_name,
    now() as inserted_at
FROM file('customer_first.parquet', 'Parquet')
WHERE customer_id IS NOT NULL