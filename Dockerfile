# 1. Sử dụng phiên bản Airflow 3.1.3 theo yêu cầu của bạn
# (Nếu sau này build lỗi "manifest unknown", nghĩa là tag này chưa public, 
# lúc đó ta mới tính tiếp. Giờ cứ stick theo plan).
FROM apache/airflow:3.1.3

# 2. Chuyển sang quyền ROOT để cài gói hệ thống
# dbt cần 'git' để tải dependencies.
# 'build-essential' cần thiết để biên dịch các thư viện C++ (nếu dbt-clickhouse cần).
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         git \
         build-essential \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# 3. Quay lại user AIRFLOW để cài thư viện Python
# Tuyệt đối không dùng root để cài pip packages cho Airflow
USER airflow

# 4. Copy file requirements
COPY requirements.txt /requirements.txt

# 5. Cài đặt dbt-clickhouse và các thư viện khác
RUN pip install --no-cache-dir -r /requirements.txt