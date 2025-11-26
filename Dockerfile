FROM apache/airflow:3.1.3


USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         git \
         build-essential \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

# 4. Copy file requirements
COPY requirements.txt /requirements.txt

# 5. Cài đặt dbt-clickhouse và các thư viện khác
RUN pip install --no-cache-dir -r /requirements.txt