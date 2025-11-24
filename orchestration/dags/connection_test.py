from airflow.sdk import DAG
from airflow.providers.standard.operators.empty import EmptyOperator
import pendulum

with DAG(
    "test_dbt_connection",
    schedule=None,
    start_date=pendulum.datetime(2025, 1, 1),
    tags=["dbt_demo", "test"],
    catchup=False
):
    EmptyOperator(task_id="hello_from_dbt_repo")
