{{
    config(
        materialized='table',
        engine='ReplacingMergeTree(updated_at)',
        order_by='product_id',
        settings={
            'index_granularity': '8192',
            'allow_nullable_key': 1
        }
    )
}}

-- Staging model for products dimension with SCD Type 1
SELECT 
    product_id,
    coalesce(product_name, '') as product_name,
    coalesce(category, 'Uncategorized') as category,
    coalesce(brand, 'Generic') as brand,
    round(greatest(coalesce(price, 0), 0.01), 2) as price,
    now() as updated_at
FROM file('products_first.parquet', 'Parquet')
WHERE product_id IS NOT NULL