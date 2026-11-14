# Olist Brazilian E-Commerce SQL Analytics & OLAP Modeling

An end-to-end SQL analytics, data hygiene auditing, and dimensional modeling project analyzing over 100,000 real-world customer orders from the Olist Brazilian E-Commerce public dataset.

## 1. Project Overview

In this project, I modeled and analyzed 100,000+ customer transactions across nine relational tables from the Kaggle Olist Brazilian E-Commerce public dataset to extract actionable commercial insights and build an analytics-ready star schema. 

I resolved data quality anomalies, calculated core business KPIs with Common Table Expressions (CTEs), performed customer and category ranking with window functions, and constructed an analytical star schema centered on delivered order items (`fact_sales`) with 100% referential integrity across four dimensions.

### Current Status
- **SQL Analytics & OLAP Modeling:** Completed (50 SQL queries across 5 phases verified in MySQL 8.0 inside Docker).
- **Power BI Reporting:** In Progress (Next milestone: building an interactive dashboard on top of the MySQL star schema).

### Environment & Tools
- **DBMS:** MySQL 8.0 running inside Docker (`ecommerce_mysql` on port `3307`)
- **Database:** `ecommerce_db`
- **Volume:** 100,000+ orders (2016–2018)
- **Currency:** Brazilian Real (BRL, R$)
- **Tech Stack:** MySQL 8.0, Docker, SQL (CTEs, Window Functions, Dimensional Modeling), Git

---

## 2. Workflow & Repository Guide

The project is organized into five standalone SQL scripts executed in numerical order:

```text
Raw CSVs (Kaggle) ──► Staging Tables (MySQL) ──► Data Quality Checks ──► Analytical KPIs ──► Star Schema (OLAP)
```

| File | Focus | Key Concepts & Questions |
|---|---|---|
| [`01_data_exploration.sql`](./01_data_exploration.sql) | **Database Exploration** | Table row counts (`UNION ALL`), order status distributions, customer state breakdowns, and product catalog profiling. |
| [`02_data_quality.sql`](./02_data_quality.sql) | **Data Quality Suite** | Primary key uniqueness tests (`HAVING COUNT(*) > 1`), temporal anomaly audits (delivery preceding purchase), cancellation rates, and invalid zero/negative payment checks. |
| [`03_business_analysis.sql`](./03_business_analysis.sql) | **Business Analytics & KPIs** | Total vs. delivered revenue, Average Order Value (AOV) via modular CTEs, delivery turnaround latency, and carrier SLA compliance rates. |
| [`04_advanced_sql.sql`](./04_advanced_sql.sql) | **Advanced Window Functions** | Category sales rankings comparing `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()`, running totals, and repeat purchase intervals using `LAG()`. |
| [`05_olap_modeling.sql`](./05_olap_modeling.sql) | **OLAP Dimensional Modeling** | Constructing `fact_sales` at the order-item grain and four dimension tables (`dim_customer`, `dim_product`, `dim_seller`, `dim_date`) with full referential integrity. |

---

## 3. How to Reproduce This Project

### Prerequisites
- Docker Desktop installed and running
- Any MySQL client (MySQL CLI, DBeaver, or DataGrip)
- Raw CSV datasets from [Kaggle Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) placed in a local `/data` folder

### Step 1: Start MySQL in Docker
```bash
docker run --name ecommerce_mysql \
  -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=your_password \
  -d mysql:8.0
```

### Step 2: Initialize Database and Tables
Connect to your container on port `3307` and create the database:
```sql
CREATE DATABASE ecommerce_db;
USE ecommerce_db;
```

### Step 3: Run the Scripts
Execute the SQL files in order:
```bash
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < 01_data_exploration.sql
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < 02_data_quality.sql
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < 03_business_analysis.sql
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < 04_advanced_sql.sql
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < 05_olap_modeling.sql
```

---

## 4. Star Schema Architecture & Verified Results

### The Analytical Star Schema

```text
                             +-------------------------------+
                             |          dim_customer         |
                             +-------------------------------+
                             | PK  customer_id               |
                             |     customer_unique_id        |
                             |     customer_city             |
                             |     customer_state            |
                             +---------------+---------------+
                                             |
                                             | (1:N)
                                             v
+-------------------------------+        +-------------------------------+
|          dim_product          |        |           fact_sales          |
+-------------------------------+        +-------------------------------+
| PK  product_id                |<-------| PK  order_id                  |
|     product_category_name     |  (1:N) | PK  order_item_id             |
|     product_weight_g          |        | FK  customer_id               |
|     product_length_cm         |        | FK  product_id                |
|     product_height_cm         |        | FK  seller_id                 |
|     product_width_cm          |        | FK  date_key                  |
+-------------------------------+        |     price (R$)                |
                                         |     freight_value (R$)        |
                                         +---------------+---------------+
                                                         |
                                 +-----------------------+-----------------------+
                                 | (1:N)                                         | (1:N)
                                 v                                               v
+-------------------------------+                               +-------------------------------+
|           dim_seller          |                               |            dim_date           |
+-------------------------------+                               +-------------------------------+
| PK  seller_id                 |                               | PK  date_key (YYYYMMDD)       |
|     seller_zip_code_prefix    |                               |     full_purchase_date        |
|     seller_city               |                               |     day, month, quarter, year |
|     seller_state              |                               +-------------------------------+
+-------------------------------+
```

### Verified Findings & Key Numbers
- **Fact Table Grain:** One row per delivered order item (`order_id`, `order_item_id`).
- **Delivered Merchandise Total:** Exactly `R$ 13,591,643.70` across 110,197 delivered order items (excluding freight), reconciled with 100% precision between raw staging and final star schema queries. Total shipping freight was `R$ 2,217,922.90`.
- **Referential Integrity:** 0 orphaned foreign keys across customer, product, seller, and date dimensions (`COUNT(*) = 110,197` on full 5-table inner join).
- **Logistics Latency:** Average delivery turnaround time was ~12.5 days, with 92% carrier on-time SLA compliance against estimated delivery dates.

### Reproducible Business Query: Monthly Delivered Sales Trend
```sql
SELECT 
    d.year,
    d.month,
    ROUND(SUM(f.price), 2) AS monthly_merchandise_sales_brl,
    COUNT(*) AS total_items_sold
FROM fact_sales f
INNER JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;
```
*Observed Finding:* Sales grew steadily from R$ 41,747.00 in January 2017 to peak in November 2017 during Black Friday at over R$ 1,000,000 in monthly sales, sustaining high transaction volume through 2018.

---

## 5. What I Learned & Key Decisions

### Key Decision: Fact Table Grain
In e-commerce databases, an order often contains multiple distinct products sold by different merchants. Defining `fact_sales` at the whole-order level would force aggregate prices and blur product-level or seller-level relationships. By defining the grain at the **order-item level** (`order_id`, `order_item_id`), each line item cleanly connects to its specific product, merchant, and individual freight cost.

### Real Challenge: Handling Missing Product Categories
During dimension modeling, I discovered 611 product records in the source dataset missing a category name. If I had filtered them out with an `INNER JOIN`, over R$ 170,000 in delivered sales items would have been dropped from the warehouse. Following Kimball dimensional modeling standards, I preserved every product record and mapped missing categories to `'Unknown'`, maintaining complete financial reconciliation down to the cent.

### Next Step
Building an interactive **Power BI** dashboard on top of the MySQL star schema to visualize category sales velocity, shipping latency by state, and customer repeat purchase patterns.

---

## Author
**Niraj Basnet**  
Computer Science Undergraduate, University of South Florida  
- Portfolio: [nirajbasnet.com.np](https://nirajbasnet.com.np)  
- LinkedIn: [linkedin.com/in/nirajbasnet009](https://www.linkedin.com/in/nirajbasnet009)  
- GitHub: [github.com/nirajbasnet009](https://github.com/nirajbasnet009)
