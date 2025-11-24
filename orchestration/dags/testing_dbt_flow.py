import os
from pathlib import Path
import pendulum
from airflow.sdk import DAG
from airflow.providers.standard.operators.bash import BashOperator
from airflow.hooks.base import BaseHook


# --- 1. ĐỊNH VỊ DỰ ÁN VÀ VENV (CRUCIAL PATH FINDING) ---
# Lấy đường dẫn file DAG hiện tại
CURRENT_FILE = Path(__file__).resolve()
# Đi ngược lên 2 cấp để tìm thư mục gốc của project (dbt_demo/)
DBT_PROJECT_DIR = CURRENT_FILE.parents[2]
# Đường dẫn kích hoạt venv của dbt (cực kỳ quan trọng để dbt chạy đúng)
DBT_VENV_ACTIVATE = DBT_PROJECT_DIR / ".venv/bin/activate"


DBT_PROFILES_ROOT = Path("/home/long/.dbt")
# --- 2. LẤY MẬT KHẨU TỪ AIRFLOW CONNECTION ---
def get_db_env():
    """Lấy credentials từ Airflow Connection và truyền vào biến môi trường."""
    try:
        # Tên Connection ID bạn đã tạo trên UI
        conn = BaseHook.get_connection("clickhouse_dbt_conn")
        return {
            "DBT_CLICKHOUSE_HOST": conn.host,
            "DBT_CLICKHOUSE_USER": conn.login,
            "DBT_CLICKHOUSE_PASSWORD": conn.password, # Mật khẩu bảo mật
            "DBT_PROFILES_DIR": str(DBT_PROFILES_ROOT)}
    except Exception as e:
        # Nếu Connection lỗi (ví dụ chưa tạo) thì DAG sẽ báo lỗi ngay
        print(f"Lỗi lấy Connection: {e}")
        raise

# --- 3. ĐỊNH NGHĨA DAG VÀ LUỒNG CHẠY ---
with DAG(
    dag_id="dbt_final_pipeline",
    schedule="@daily",
    start_date=pendulum.datetime(2025, 1, 1, tz="UTC"),
    catchup=False,
    tags=["dbt", "production", "final"],
) as dag:

    dbt_env = get_db_env()
    
    # Prefix cho mọi lệnh: Kích hoạt venv dbt -> Chạy dbt
    DBT_CMD_PREFIX = f"source {DBT_VENV_ACTIVATE} && dbt --no-write-json"

    # Task 1: Seeds (Nạp dữ liệu tĩnh)
    dbt_seed = BashOperator(
        task_id="dbt_seed",
        bash_command=f"{DBT_CMD_PREFIX} seed --project-dir {DBT_PROJECT_DIR}",
        env=dbt_env, # Truyền Env Vars vào process dbt
        cwd=DBT_PROJECT_DIR, # Chạy lệnh từ thư mục gốc dbt
    )

    # Task 2: Run (Chạy toàn bộ model)
    dbt_run = BashOperator(
        task_id="dbt_run_models",
        bash_command=f"{DBT_CMD_PREFIX} run --project-dir {DBT_PROJECT_DIR} --fail-fast",
        env=dbt_env,
        cwd=DBT_PROJECT_DIR,
    )

    # Task 3: Test (Kiểm tra chất lượng dữ liệu)
    dbt_test = BashOperator(
        task_id="dbt_test_quality",
        bash_command=f"{DBT_CMD_PREFIX} test --project-dir {DBT_PROJECT_DIR}",
        env=dbt_env,
        cwd=DBT_PROJECT_DIR,
    )

    # Luồng: Seed -> Run -> Test
    dbt_seed >> dbt_run >> dbt_test