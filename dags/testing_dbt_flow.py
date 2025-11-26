import os
from pathlib import Path
import pendulum

# --- 1. DÙNG IMPORT CHUẨN AIRFLOW 3 (Giống File 1) ---
from airflow.sdk import DAG
from airflow.providers.standard.operators.bash import BashOperator
# Hook vẫn phải lấy từ base cũ (hoặc sdk nếu có, nhưng base là an toàn nhất hiện tại)
from airflow.hooks.base import BaseHook

# --- CẤU HÌNH ĐƯỜNG DẪN CỐ ĐỊNH TRONG DOCKER ---
DBT_PROJECT_DIR = "/opt/airflow/dbt_project"

def get_db_env():
    """
    Hàm này lấy mật khẩu từ Airflow Connection.
    Nếu lỗi, nó trả về cấu hình mặc định trỏ host về 'clickhouse' (tên service docker)
    chứ không phải 'localhost' (vì localhost trong docker là chính nó).
    """
    try:
        conn = BaseHook.get_connection("clickhouse_dbt_conn")
        return {
            "DBT_CLICKHOUSE_HOST": conn.host,
            "DBT_CLICKHOUSE_USER": conn.login,
            "DBT_CLICKHOUSE_PASSWORD": conn.password,
            "DBT_CLICKHOUSE_PORT": str(conn.port),
            "DBT_PROFILES_DIR": DBT_PROJECT_DIR,
        }
    except Exception as e:
        print(f"⚠️ Warning: Không lấy được connection 'clickhouse_dbt_conn'. Lỗi: {e}")
        # Fallback: Cố gắng dùng cấu hình mặc định cho Docker
        return {
            "DBT_CLICKHOUSE_HOST": "clickhouse",  # Tên service trong docker-compose
            "DBT_CLICKHOUSE_USER": "default",
            "DBT_CLICKHOUSE_PASSWORD": "123456", # Hardcode fallback để test (nếu cần)
            "DBT_CLICKHOUSE_PORT": "8123",
            "DBT_PROFILES_DIR": DBT_PROJECT_DIR,
        }

with DAG(
    dag_id="dbt_final_pipeline",
    schedule="@daily",
    start_date=pendulum.datetime(2025, 1, 1, tz="UTC"),
    catchup=False,
    tags=["dbt", "docker", "airflow3"],
) as dag:

    dbt_env = get_db_env()
    
    # Lệnh dbt
    DBT_CMD = "dbt --no-write-json"

    # --- Task 1: Debug (KÈM IN BIẾN MÔI TRƯỜNG) ---
    # Tôi thêm lệnh 'env' để in ra log xem nó nhận được password chưa
    dbt_debug = BashOperator(
        task_id="dbt_debug",
        bash_command=f"echo '--- CHECK ENV ---' && env | grep DBT && echo '--- RUN DBT ---' && {DBT_CMD} debug --profiles-dir {DBT_PROJECT_DIR}",
        env=dbt_env,
        cwd=DBT_PROJECT_DIR, # Đã có cwd thì không cần 'cd ... &&' nữa
        append_env=True,     # Lấy thêm PATH của hệ thống để tìm lệnh dbt
    )

    # Task 2: Seed
    dbt_seed = BashOperator(
        task_id="dbt_seed",
        bash_command=f"{DBT_CMD} seed --project-dir {DBT_PROJECT_DIR}",
        env=dbt_env,
        cwd=DBT_PROJECT_DIR,
        append_env=True,  
    )

    # Task 3: Run
    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"{DBT_CMD} run --project-dir {DBT_PROJECT_DIR}",
        env=dbt_env,
        cwd=DBT_PROJECT_DIR,
        append_env=True,  
    )

    # Task 4: Test
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"{DBT_CMD} test --project-dir {DBT_PROJECT_DIR}",
        env=dbt_env,
        cwd=DBT_PROJECT_DIR,
        append_env=True,  
    )

    dbt_debug >> dbt_seed >> dbt_run >> dbt_test