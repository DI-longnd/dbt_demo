{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='region_id',
        settings={
            'index_granularity': '8192'
        }
    )
}}

-- Staging model for regions dimension
SELECT 
    coalesce(region_id, '') as region_id,
    coalesce(region, '') as region
FROM file('regions.parquet', 'Parquet')
WHERE region_id IS NOT NULL AND region_id != ''