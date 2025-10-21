# dbt + ClickHouse Analytics Pipeline

Một pipeline dữ liệu hoàn chỉnh minh họa sức mạnh của dbt với ClickHouse để phân tích khách hàng.

## 📋 Mục lục
* [Tổng quan](#-tổng-quan)
* [Kiến trúc](#-kiến-trúc)
* [Điều kiện tiên quyết](#-điều-kiện-tiên-quyết)
* [Hướng dẫn nhanh](#-hướng-dẫn-nhanh)
* [Cấu trúc dự án](#-cấu-trúc-dự-án)
* [Các tầng Pipeline](#-các-tầng-pipeline)
* [Chạy Pipeline](#-chạy-pipeline)
* [Tính năng chính](#-tính-năng-chính)
* [Truy vấn mẫu](#-truy-vấn-mẫu)
* [Xử lý sự cố](#-xử-lý-sự-cố)
* [Tài nguyên tham khảo](#-tài-nguyên-tham-khảo)
* [Đóng góp](#-đóng-góp)
* [Giấy phép](#-giấy-phép)

---

## 🎯 Tổng quan

Dự án này minh họa một pipeline phân tích hoàn chỉnh sử dụng **dbt** (data build tool) và **ClickHouse** để phân tích hành vi khách hàng và hiệu suất bán hàng.

**Các câu hỏi nghiệp vụ được trả lời:**
* Ai là những khách hàng giá trị nhất của chúng ta?
* Xu hướng doanh thu hàng tháng của chúng ta là gì?
* Những khách hàng nào có nguy cơ rời bỏ (churn)?
* Tăng trưởng tháng-qua-tháng (month-over-month) của chúng ta là bao nhiêu?

---

## 🏗️ Kiến trúc

**Raw Data (Parquet)** → **Staging** → **Intermediate** → **Marts** → **Analytics/BI**

**Luồng Pipeline:**
1.  **Tầng Staging:** Làm sạch và chuẩn hóa dữ liệu thô.
2.  **Tầng Intermediate:** Áp dụng logic nghiệp vụ và làm giàu dữ liệu.
3.  **Tầng Marts:** Tạo các bảng sẵn sàng cho phân tích (analytics-ready) cho dashboard.

---

## ✅ Điều kiện tiên quyết

### Phần mềm yêu cầu
* Docker (cho ClickHouse)
* Python 3.8+
* Adapter `dbt-clickhouse`

### File dữ liệu
Bạn cần các file Parquet sau:
* `regions.parquet`
* `customers.parquet`
* `products.parquet`
* `orders.parquet`

---

## 🚀 Hướng dẫn nhanh

### Bước 1: Cài đặt ClickHouse với Docker

```bash
# Chạy ClickHouse container
docker run -d \
  --name clickhouse-local \
  -p 9000:9000 \
  -p 18123:8123 \
  clickhouse/clickhouse-server

# Xác minh container đang chạy
docker ps | grep clickhouse

```

### Bước 2: Sao chép file dữ liệu vào ClickHouse


```bash
# Sao chép các file Parquet vào ClickHouse container
docker cp /path/to/regions.parquet clickhouse-local:/var/lib/clickhouse/user_files/
docker cp /path/to/customers.parquet clickhouse-local:/var/lib/clickhouse/user_files/
docker cp /path/to/products.parquet clickhouse-local:/var/lib/clickhouse/user_files/
docker cp /path/to/orders.parquet clickhouse-local:/var/lib/clickhouse/user_files/

# Xác minh các file đã được sao chép
docker exec clickhouse-local ls -la /var/lib/clickhouse/user_files/
```


### Bước 3: Cài đặt dbt và các thư viện phụ thuộc

# Tạo môi trường ảo (khuyến nghị)
```bash
uv venv
source venv/bin/activate  
```
# Cài đặt dbt-clickhouse
```bash
uv pip install dbt-clickhouse
```
# Xác minh cài đặt
```bash
dbt --version
```

### Bước 4: Cấu hình dbt Profile
Tạo/chỉnh sửa file ~/.dbt/profiles.yml:

```bash
my_clickhouse_project:
  target: dev
  outputs:
    dev:
      type: clickhouse
      driver: http
      host: localhost
      port: 18123
      user: default
      password: ""
      database: default
      schema: default
      secure: false
      verify: false
      threads: 4
```



### Bước 5: Khởi tạo dự án dbt
```bash
# Nếu bắt đầu từ đầu
dbt init my_clickhouse_project
cd my_clickhouse_project

# Kiểm tra kết nối
dbt debug
```



### Bước 6: Thiết lập cấu trúc dự án

```bash
# Tạo cấu trúc thư mục
mkdir -p models/staging
mkdir -p models/intermediate
mkdir -p models/marts
mkdir -p tests
mkdir -p macros

# Tạo sources.yml
touch models/sources.yml

# Tạo schema.yml cho marts
touch models/marts/schema.yml
```



### Bước 7: Tạo các model dbt

```bash
Sao chép các file model vào các thư mục thích hợp:

- Staging Models (models/staging/):
+ stg_regions.sql
+ stg_customers.sql
+ stg_products.sql
+ stg_orders.sql

- Intermediate Models (models/intermediate/):
+ int_orders_enriched.sql
+ int_customer_monthly_metrics.sql

- Marts Models (models/marts/):
+ mart_customer_lifetime_value.sql
+ mart_monthly_sales_summary.sql

```

### Bước 8: Chạy Pipeline
```bash
# Chạy tất cả các model theo thứ tự
dbt run

# Hoặc chạy theo tầng
dbt run --select staging.*
dbt run --select intermediate.*
dbt run --select marts.*

# Chạy tests
dbt test

# Tạo tài liệu
dbt docs generate
dbt docs serve  # Mở trình duyệt với biểu đồ lineage tương tác
```

### 📁 Cấu trúc dự án
```bash
my_clickhouse_project/
├── dbt_project.yml           # Cấu hình dự án
├── models/
│   ├── sources.yml           # Định nghĩa các nguồn
│   ├── staging/              # Tầng 1: Làm sạch dữ liệu thô
│   │   ├── stg_regions.sql
│   │   ├── stg_customers.sql
│   │   ├── stg_products.sql
│   │   └── stg_orders.sql
│   ├── intermediate/         # Tầng 2: Logic nghiệp vụ
│   │   ├── int_orders_enriched.sql
│   │   └── int_customer_monthly_metrics.sql
│   └── marts/                # Tầng 3: Sẵn sàng cho phân tích
│       ├── schema.yml
│       ├── mart_customer_lifetime_value.sql
│       └── mart_monthly_sales_summary.sql
├── tests/                    # Các test tùy chỉnh
├── macros/                   # Các macro SQL tái sử dụng
└── target/                   # SQL đã biên dịch (tự động tạo)
```


### 🏃 Chạy Pipeline

## Chạy mọi thứ
```bash
dbt run
```


## Chạy chọn lọc
```bash
# Chỉ chạy tầng staging
dbt run --select staging.*

# Chạy một model cụ thể và các model phụ thuộc của nó (upstream)
dbt run --select +mart_customer_lifetime_value

# Chạy một model và mọi thứ phía sau nó (downstream)
dbt run --select stg_orders+

# Chạy lại từ đầu (drop và tạo lại)
dbt run --full-refresh
```


## Testing
```bash
# Chạy tất cả các test
dbt test

# Test một model cụ thể
dbt test --select mart_customer_lifetime_value

# Test các nguồn
dbt test --select source:*
```


## Documentation
```bash
# Tạo docs
dbt docs generate

# Chạy docs local (mở trình duyệt)
dbt docs serve
```