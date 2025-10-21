{% macro get_date_parts(date_column) %}
    toYear({{ date_column }}) as year,
    toQuarter({{ date_column }}) as quarter,
    toMonth({{ date_column }}) as month,
    toDayOfWeek({{ date_column }}) as day_of_week,
    toStartOfMonth({{ date_column }}) as month_start_date
{% endmacro %}