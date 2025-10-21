{% test valid_email(model, column_name) %}

SELECT
    {{ column_name }}
FROM {{ model }}
WHERE {{ column_name }} != ''
  AND {{ column_name }} NOT LIKE '%@%.%'

{% endtest %}