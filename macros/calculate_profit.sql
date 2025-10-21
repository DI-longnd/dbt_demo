{% macro calculate_profit(revenue_column, margin_pct=30) %}
    round({{ revenue_column }} * {{ margin_pct }} / 100, 2)
{% endmacro %}