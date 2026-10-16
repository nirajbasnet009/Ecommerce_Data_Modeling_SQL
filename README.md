# Olist Brazilian E-Commerce SQL Analytics, Data Quality & OLAP Modeling

A comprehensive SQL analytics, data quality validation, and dimensional data modeling project analyzing over 100,000 real-world customer transactions from the Olist Brazilian E-Commerce public dataset.

> **Project Status: Active Work in Progress**  
> Phases 1 through 4 (Exploration, Data Quality Auditing, Business Analysis, and Advanced Window Functions) are complete. Phase 5 (OLAP Dimensional Modeling and Star Schema Design) is currently in progress. Regular commits will be added as remaining queries and dimensional tables are finalized.

---

## 1. Project Overview

This project models and analyzes an enterprise-scale e-commerce database to extract actionable business insights and establish data quality safeguards. The objective is to evaluate customer purchasing behavior, revenue streams, logistics performance, and payment anomalies across nine relational tables, followed by designing an analytics-friendly star schema for reporting.

### Environment & Tools
- **DBMS:** MySQL 8.0 running inside a Docker container (`ecommerce_mysql` on port 3307)
- **Database Name:** `ecommerce_db`
- **Data Volume:** 100,000+ orders spanning 2016 to 2018
- **Core Technologies:** Docker, MySQL, SQL (CTEs, Window Functions, Multi-Table Joins, Data Modeling), Git

---

## 2. Dataset Architecture & Source

> **Dataset Source:** [Brazilian E-Commerce Public Dataset by Olist on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)  
> *Note: To keep this repository lightweight and follow software engineering best practices, raw CSV data files are excluded via `.gitignore`. You can download the complete archive directly from the Kaggle link above and place the CSV files inside a `/data` folder.*

The project analyzes the following 9 relational tables:

| Dataset File | Records | Description |
|---|---|---|
| `olist_orders_dataset.csv` | ~99k | Order lifecycle, status (delivered, canceled), purchase and delivery timestamps |
| `olist_order_items_dataset.csv` | ~112k | Line-item details, pricing, freight charges, product and seller foreign keys |
| `olist_customers_dataset.csv` | ~99k | Customer demographics, ZIP prefix, city, and Brazilian state codes |
| `olist_products_dataset.csv` | ~32k | Product dimensions, weights, and Portuguese category names |
| `olist_order_payments_dataset.csv` | ~103k | Payment types (credit card, boleto, voucher), installments, and transaction values |
| `olist_sellers_dataset.csv` | ~3k | Seller locations across Brazilian municipalities |
| `olist_order_reviews_dataset.csv` | ~100k | Customer review scores (1-5) and feedback timestamps |
| `olist_geolocation_dataset.csv` | ~1M | Geographic coordinates and ZIP code prefixes across Brazil |
| `product_category_name_translation.csv` | 71 | English translation mapping for Portuguese category names |

---

## 3. Project Structure & SQL Phases

### `01_data_exploration.sql` (Phase 1: Database Exploration)
- Overview of record counts across all nine tables using `UNION ALL`.
- Distinct customer count vs. total customer records.
- Distribution of order statuses (`delivered`, `canceled`, `shipped`, `invoiced`).
- Geographic distribution of customers across Brazilian states.
- Product catalog analysis: top product categories, missing category audits, and weight statistics (`MIN`, `MAX`, `AVG`).

### `02_data_quality.sql` (Phase 2: Data Quality & Hygiene Suite)
- **Primary Key Integrity:** Checks for duplicate `customer_id` and `order_id` records using `GROUP BY` and `HAVING COUNT(*) > 1`.
- **Temporal Constraint Auditing:** Verification queries detecting orders where the delivery timestamp precedes the purchase timestamp.
- **Cancellation Rate Auditing:** Conditional aggregations (`SUM(CASE WHEN...)`) measuring the overall cancellation percentage across all orders.
- **Null Value Checks:** Auditing missing product weights, dimensions, and customer address records.
- **Financial Anomaly Detection:** Identification of invalid payment values (zero and negative payments).

### `03_business_analysis.sql` (Phase 3: Business Analytics & KPIs)
- **Multi-Table Joins:** Joins linking up to three tables (`orders`, `order_items`, `products`, `sellers`, `customers`).
- **Revenue Performance:** Total merchandise revenue vs. delivered merchandise revenue.
- **Category & Seller Rankings:** Identification of the top 10 revenue-generating product categories and top 10 sellers by state.
- **Average Order Value (AOV):** Modular Common Table Expressions (`WITH order_totals AS (...)`) calculating the average spend per delivered order.
- **Logistics & Fulfillment Performance:**
  - Average shipping turnaround latency calculated using `TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)`.
  - On-time delivery SLA compliance percentage calculated by comparing actual delivery dates against estimated delivery dates.

### `04_advanced_sql.sql` (Phase 4: Advanced Analytical SQL)
- Window functions for category sales ranking: comparing `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()`.
- Customer order sequence tracking and multi-period trend analysis using windowing logic.

### `05_olap_modeling.sql` (Phase 5: OLAP & Dimensional Data Modeling — In Progress)
- Transitioning the relational schema into an analytical star schema.
- **Fact Table Design (`fact_sales`):** Defining fact table grain at the order-item level (`order_id`, `order_item_id`).
- **Data Type Normalization:** Schema adjustments enforcing strict data types (`DECIMAL(12,2)` for financial fields, `DATETIME` for timestamps, explicit string lengths).
- Fact table integrity checks: verifying surrogate keys, absence of nulls in primary identifiers, and referential validity.
- *(Upcoming commits will introduce dimension tables: `dim_customer`, `dim_product`, `dim_date`, and OLAP aggregation queries).*

---

## 4. Key SQL Concepts Demonstrated

- **Multi-Table Joins:** `INNER JOIN` operations joining three or more tables with strict filtering.
- **Common Table Expressions (CTEs):** Readable, modular SQL queries using `WITH` blocks.
- **Conditional Aggregations:** `SUM(CASE WHEN...)` and `COUNT(CASE WHEN...)` for rate calculations.
- **Window Functions:** `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()` with `PARTITION BY` and `ORDER BY`.
- **Date & Time Operations:** `TIMESTAMPDIFF`, `DATE()`, and timestamp formatting.
- **Data Hygiene Testing:** Detecting duplicates, orphan records, and boundary violations.
- **Dimensional Modeling:** Fact table creation, grain specification, and data type casting.

---

## 5. How to Run This Project Locally

### Prerequisites
- Docker Desktop installed and running
- MySQL Client, DBeaver, or VS Code Database extension
- Raw CSV datasets downloaded from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

### Step 1: Start MySQL in Docker
```bash
docker run --name ecommerce_mysql \
  -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=your_password \
  -d mysql:latest
```

### Step 2: Create Database
Connect to your container on port `3307` and create the database:
```sql
CREATE DATABASE ecommerce_db;
USE ecommerce_db;
```

### Step 3: Load Data
Download the dataset from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), place the files in a local `/data` directory, and import the CSV files into their corresponding tables.

### Step 4: Execute Scripts
Execute the SQL files in numerical order:
1. `01_data_exploration.sql`
2. `02_data_quality.sql`
3. `03_business_analysis.sql`
4. `04_advanced_sql.sql`
5. `05_olap_modeling.sql`

---

## 6. Author & Contact

**Niraj Basnet**  
Computer Science Undergraduate, University of South Florida (Tampa, FL)  
- Email: nirajbasnet@usf.edu  
- LinkedIn: [linkedin.com/in/nirajbasnet009](https://www.linkedin.com/in/nirajbasnet009)  
- GitHub: [github.com/nirajbasnet009](https://github.com/nirajbasnet009)
