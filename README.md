<div align="center">

# 🛒 Olist Brazilian E-Commerce Analytics & Dimensional Modeling

### End-to-end SQL analytics, data hygiene auditing, and star schema modeling on 100k+ Brazilian customer orders in MySQL 8.0 & Docker, with an executive Power BI dashboard.

<p>
  <img src="https://img.shields.io/badge/Power%20BI-Executive%20Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=000000" alt="Power BI">
  <img src="https://img.shields.io/badge/MySQL%208.0-Database%20Engine-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL 8.0">
  <img src="https://img.shields.io/badge/Docker-Containerized-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/SQL-Analytics%20%26%20OLAP-336791?style=for-the-badge&logo=postgresql&logoColor=white" alt="SQL">
  <img src="https://img.shields.io/badge/DAX-Time%20Intelligence-0078D4?style=for-the-badge&logo=microsoft&logoColor=white" alt="DAX">
</p>

<p>
  <img src="https://img.shields.io/badge/Data%20Model-Kimball%20Star%20Schema-6F42C1?style=flat-square" alt="Star Schema">
  <img src="https://img.shields.io/badge/Orders-96%2C478%20Delivered-0A66C2?style=flat-square" alt="Orders">
  <img src="https://img.shields.io/badge/Delivered%20Sales-R%24%2013.22M-2EA44F?style=flat-square" alt="Delivered Sales">
  <img src="https://img.shields.io/badge/Referential%20Integrity-100%25%20(0%20Orphans)-brightgreen?style=flat-square" alt="100% Integrity">
  <img src="https://img.shields.io/badge/Calendar-1%2C096%20Days%20Continuous-blueviolet?style=flat-square" alt="Calendar Continuity">
  <img src="https://img.shields.io/badge/License-MIT-8A2BE2?style=flat-square" alt="MIT License">
</p>

<br>

<a href="powerbi/ecommercereport.pbix">
  <img src="https://img.shields.io/badge/📊%20VIEW%20DASHBOARD-111827?style=for-the-badge" alt="View Dashboard">
</a>
&nbsp;
<a href="https://nirajbasnet.com.np/blog/olist-ecommerce-sql-analytics-and-olap-modeling/">
  <img src="https://img.shields.io/badge/📄%20READ%20CASE%20STUDY-111827?style=for-the-badge" alt="Read Case Study">
</a>
&nbsp;
<a href="05_olap_modeling.sql">
  <img src="https://img.shields.io/badge/🔎%20EXPLORE%20SQL-111827?style=for-the-badge" alt="Explore SQL">
</a>

<br><br>

<sub>Portfolio project by <b>Niraj Basnet</b> (Computer Science, University of South Florida)</sub>

</div>

---

<p align="center">
  <img src="docs/images/executive-sales-overview.png" alt="Olist E-Commerce Executive Sales & Revenue Overview Dashboard" width="100%">
</p>

<div align="center">

### 💰 R$ 13.22M Delivered Sales &nbsp;•&nbsp; 📦 96,478 Orders &nbsp;•&nbsp; 🎯 R$ 137.04 AOV &nbsp;•&nbsp; 🚚 R$ 2.20M Freight &nbsp;•&nbsp; 💎 R$ 15.42M Gross Delivered Value

</div>

---

## 🧭 Quick Navigation

<p align="center">
  <a href="#-project-overview">Overview</a> •
  <a href="#-executive-scorecard--reconciliation">Scorecard</a> •
  <a href="#-monthly-revenue-trend">Monthly Trend</a> •
  <a href="#-power-bi-executive-dashboard">Power BI Dashboard</a> •
  <a href="#-star-schema-architecture">Star Schema</a> •
  <a href="#-bi-hardening-real-engineering-fixes">BI Hardening</a> •
  <a href="#-analytics-workflow--scripts">SQL Scripts</a> •
  <a href="#-how-to-reproduce-this-project">Reproduce</a> •
  <a href="#-repository-structure">Repository</a>
</p>

---

# 📌 Project Overview

In this project, I modeled and analyzed **100,000+ real-world customer transactions** across nine relational tables from the Kaggle Olist Brazilian E-Commerce public dataset to extract actionable commercial insights and build an analytics-ready dimensional warehouse.

The project connects the full lifecycle of modern analytics engineering:

<div align="center">

<br>

**Raw Kaggle CSVs ──► Staging Tables ──► Data Hygiene Audits ──► Analytical KPIs ──► Kimball Star Schema ──► BI Hardening Migrations ──► Power BI Executive Dashboard**

</div>

<br>

Rather than analyzing tables in isolation, this project resolves messy production anomalies (order vs. customer grain, calendar discontinuity, missing translations), guarantees **100% referential integrity** with zero orphaned records, reconciles every business KPI to the exact cent between SQL and DAX, and delivers an interactive, executive-grade Power BI dashboard.

### 🏆 What This Project Demonstrates

<table>
<tr>
<td width="50%" valign="top">

### 📊 BI & Visualization
- Executive dashboard architecture
- Soft-slate custom theme (`#F4F5F7` & `#0F2C59`)
- Time-intelligence trend visualization
- Gapless timeline slicers & visual hierarchy

### 🧱 Data & Dimensional Modeling
- Kimball dimensional star schema
- Fact table at order-item grain (`110,197` rows)
- Strict 1:N single-direction relationships
- 100% referential integrity (0 orphaned FKs)

</td>
<td width="50%" valign="top">

### 🧮 Advanced SQL Analytics
- Window functions (`ROW_NUMBER`, `RANK`, `LAG`)
- Modular CTEs for AOV and turnaround latency
- Automated data hygiene & anomaly audits
- Category ranking and running totals

### 🛡️ Production BI Hardening
- True customer entity grain remodeling (`2,801` repeat buyers)
- 1,096-day continuous calendar dimension
- Defensive English translations (`COALESCE`)
- Exact cent SQL-to-DAX KPI reconciliation

</td>
</tr>
</table>

---

# 🎯 Executive Scorecard & Reconciliation

Every headline metric in the Power BI dashboard was mathematically reconciled against MySQL 8.0 OLAP queries to ensure 100% reporting integrity:

| Metric | Business Definition | MySQL 8.0 Ground Truth | Power BI DAX Measure | Status |
|---|---|---|---|:---:|
| **Delivered Merchandise Revenue** | Net merchandise value across all delivered items | `R$ 13,221,498.11` | `[Total Delivered Merchandise Revenue]` | ✅ **100% Match** |
| **Delivered Freight Value** | Total shipping freight paid on delivered orders | `R$ 2,198,275.64` | `[Total Freight Cost]` | ✅ **100% Match** |
| **Gross Delivered Value** | Total customer expenditure (merchandise + freight) | `R$ 15,419,773.75` | `[Total Gross Delivered Value]` | ✅ **100% Match** |
| **Delivered Order Count** | Unique delivered purchase transactions | `96,478` orders | `[Total Delivered Orders]` | ✅ **100% Match** |
| **Delivered Item Count** | Total individual product units fulfilled | `110,197` items | `COUNTROWS(fact_sales)` | ✅ **100% Match** |
| **Average Order Value (AOV)** | Average merchandise spend per delivered order | `R$ 137.04` | `[Average Order Value]` | ✅ **100% Match** |
| **Unique Customer Count** | Distinct human individuals (`customer_unique_id`) | `96,096` customers | `DISTINCTCOUNT(dim_customer[customer_unique_id])` | ✅ **100% Match** |
| **Repeat Buyers** | Customers with ≥ 2 delivered orders | `2,801` customers | `CALCULATE(DISTINCTCOUNT(...))` | ✅ **100% Match** |
| **Calendar Span** | Gapless timeline continuity | `1,096` days | `COUNTROWS(dim_date)` | ✅ **100% Match** |
| **Referential Integrity** | Orphaned foreign keys across all 4 dimensions | `0` orphans | `Relationships (1:N single)` | ✅ **100% Match** |

---

# 📈 Monthly Revenue Trend

<p align="center">
  <img src="docs/images/monthly-merchandise-revenue.png" alt="Monthly Merchandise Revenue Trend" width="100%">
</p>

*The dual-line visual compares monthly merchandise sales in Brazilian Reais (R$) against the same month in the prior year (`SAMEPERIODLASTYEAR`), illustrating seasonal velocity, compound annual growth, and platform expansion across the 2016–2018 Olist order lifecycle.*

### 💡 Key Commercial Observations:
- **November 2017 Black Friday Surge:** Delivered sales peaked at **R$ 1,005,622.37** in November 2017, representing a dramatic **323% YoY increase** fueled by nationwide e-commerce promotional events.
- **Sustained Baseline Growth:** Baseline monthly sales stabilized at over **R$ 850k–950k/month** throughout 2018, demonstrating sticky consumer adoption following initial peak campaigns.
- **Delivery Turnaround:** Average carrier delivery latency stood at **12.5 days**, with **92.1%** of orders delivered strictly before the promised customer SLA date.

---

# 📊 Power BI Executive Dashboard

The interactive Power BI dashboard (`ecommercereport.pbix`) is engineered using a custom executive theme, strict 1:N single-direction relationships, and centralized DAX measures:

- **Report Artifact:** [`powerbi/ecommercereport.pbix`](powerbi/ecommercereport.pbix)
- **Design System:** Custom Soft-Slate Executive Palette (`#F4F5F7` canvas, `#0F2C59` navy accents, card shadows, high-contrast typography)
- **Centralized Logic:** Dedicated `_Measures` table housing all Time-Intelligence, KPI, and growth calculations.

### Report Pages Overview:
1. **Executive Sales & Revenue Overview:** Headline scorecard, dual-line monthly YoY revenue comparison, daily sales velocity by day of week (weekday vs. weekend), and interactive gapless date slicer.
2. **Product & Regional Deep-Dive:** Top 10 English product categories, geographic revenue concentration matrix by Brazilian State (`SP`, `RJ`, `MG`), and freight-to-merchandise impact ratios.
3. **Customer Cohorts & Lifetime Value:** Repeat customer purchasing intervals (`LAG()`), new vs. repeat customer contribution, and average items per transaction.

---

# 🧱 Star Schema Architecture

The analytical warehouse follows a strict Kimball dimensional modeling architecture centered on delivered order items:

```text
                             +-------------------------------+
                             |          dim_customer         |
                             +-------------------------------+
                             | PK  customer_unique_id        |
                             |     customer_zip_code_prefix  |
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
|     product_category_english  |        | FK  customer_unique_id        |
|     product_weight_g          |        |     customer_id (checkout)    |
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
|     seller_zip_code_prefix    |                               |     full_date (DATE)          |
|     seller_city               |                               |     day_number, day_name      |
|     seller_state              |                               |     month_number, month_name  |
+-------------------------------+                               |     year_month_code, quarter  |
                                                                |     year, is_weekend          |
                                                                +-------------------------------+
```

### Verified Findings & Ground Truth Numbers
- **Fact Table Grain:** One row per delivered order item (`order_id`, `order_item_id`).
- **Delivered Merchandise Sales:** Exactly **R$ 13,221,498.11** across 110,197 delivered order items (excluding shipping). Total shipping freight was **R$ 2,198,275.64**, bringing total gross delivered value to **R$ 15,419,773.75**. Across all order statuses (including canceled, shipped, processing), raw demand totaled R$ 13,591,643.70.
- **Unique Customers:** Exactly **96,096 unique customer individuals** (`customer_unique_id`) across 99,441 order checkout tokens (`customer_id`).
- **Repeat Buyers Detected:** Exactly **2,801 customers** completed 2 or more delivered orders (and 2,997 across all order attempts).
- **Referential Integrity:** 0 orphaned foreign keys across customer, product, seller, and date dimensions (`COUNT(*) = 110,197` on full 5-table inner join).
- **Calendar Continuity:** 1,096 continuous calendar days spanning 2016-01-01 through 2018-12-31 with zero gaps, guaranteeing complete compatibility with Power BI DAX Time-Intelligence functions.

### Reproducible Business Query: Monthly Delivered Sales Trend
```sql
SELECT 
    d.year,
    d.month_number,
    d.month_name,
    ROUND(SUM(f.price), 2) AS monthly_merchandise_sales_brl,
    COUNT(*) AS total_items_sold
FROM fact_sales f
INNER JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month_number, d.month_name
ORDER BY d.year, d.month_number;
```

---

# 🛡️ BI Hardening: Real Data Engineering Fixes

Building a production-ready star schema for Power BI required solving three real-world data engineering hurdles through modular migration scripts:

### 1. Remodeling Customer Grain (`customer_id` vs `customer_unique_id`)
* **Problem:** In Olist, `customer_id` is an order checkout token generated per purchase, while `customer_unique_id` represents the real human individual. Using `customer_id` as the primary key meant repeat buyers were modeled as separate people, resulting in an artificial 0.00% repeat customer rate in BI.
* **Engineering Fix ([`01_patch_dim_customer_grain.sql`](./migrations/01_patch_dim_customer_grain.sql)):** Remodeled `dim_customer` to true entity grain (deduplicated by `customer_unique_id` using window function `ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY customer_id DESC)`), backfilled `customer_unique_id` into `fact_sales`, and established a clean 1:N relationship. This successfully unlocked customer lifetime analytics and accurately surfaced **2,801 delivered repeat buyers**.

### 2. Calendar Continuity for Power BI DAX Support
* **Problem:** Extracting dates strictly from sales transactions created 102 calendar gaps (days with zero orders, especially in late 2016). When imported into Power BI, missing dates break DAX Time-Intelligence functions (`SAMEPERIODLASTYEAR`, `DATEADD`, `TOTALYTD`).
* **Engineering Fix ([`02_patch_dim_date_continuity.sql`](./migrations/02_patch_dim_date_continuity.sql)):** Rebuilt `dim_date` into a gapless calendar dimension of all **1,096 days** (2016–2018) with built-in chronological sorting keys (`month_number`), timeline codes (`year_month_code`), day names, and weekend flags.

### 3. Defensive Category Translations with `COALESCE`
* **Problem:** `dim_product` originally stored only Portuguese categories. Joining the raw 71-row translation table dropped 624 products (611 Kimball `'Unknown'` products + unmapped categories like `pc_gamer`).
* **Engineering Fix ([`03_patch_dim_product_english.sql`](./migrations/03_patch_dim_product_english.sql)):** Added `product_category_name_english` using a systematic `COALESCE(t.product_category_name_english, p.product_category_name, 'Uncategorized')` pattern, ensuring 100% of products display clean English labels with zero dropped rows and zero `(Blank)` visual defects in BI.

---

# 🧭 Analytics Workflow & Scripts

The project is organized into five standalone SQL scripts executed in numerical order, followed by automated migration patches:

| File | Focus | Key Concepts & Questions |
|---|---|---|
| [`01_data_exploration.sql`](./01_data_exploration.sql) | **Database Exploration** | Table row counts (`UNION ALL`), order status distributions, customer state breakdowns, and product catalog profiling. |
| [`02_data_quality.sql`](./02_data_quality.sql) | **Data Quality Suite** | Primary key uniqueness tests (`HAVING COUNT(*) > 1`), temporal anomaly audits, cancellation rates, and invalid zero/negative payment checks. |
| [`03_business_analysis.sql`](./03_business_analysis.sql) | **Business Analytics & KPIs** | Total vs. delivered revenue, Average Order Value (AOV) via modular CTEs, delivery turnaround latency, and carrier SLA compliance rates. |
| [`04_advanced_sql.sql`](./04_advanced_sql.sql) | **Advanced Window Functions** | Category sales rankings comparing `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()`, running totals, and repeat purchase intervals using `LAG()`. |
| [`05_olap_modeling.sql`](./05_olap_modeling.sql) | **OLAP Dimensional Modeling** | Constructing `fact_sales` at the order-item grain and four dimension tables (`dim_customer`, `dim_product`, `dim_seller`, `dim_date`) with full referential integrity. |
| [`migrations/`](./migrations/) | **BI Schema Hardening** | Modular schema migrations for true customer entity grain, calendar continuity (1,096 days), and English category translation fallbacks. |

---

# 🚀 How to Reproduce This Project

### Prerequisites
- Docker Desktop installed and running
- Any MySQL client (MySQL CLI, MySQL Workbench, DBeaver, or DataGrip)
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

### Step 3: Run the Scripts & Migrations
Execute the foundational SQL files in order:
```bash
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < 01_data_exploration.sql
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < 02_data_quality.sql
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < 03_business_analysis.sql
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < 04_advanced_sql.sql
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < 05_olap_modeling.sql

# Execute BI Hardening Migrations:
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < migrations/01_patch_dim_customer_grain.sql
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < migrations/02_patch_dim_date_continuity.sql
mysql -h 127.0.0.1 -P 3307 -u root -p ecommerce_db < migrations/03_patch_dim_product_english.sql
```

---

# 📁 Repository Structure

```text
Ecommerce_Data_Modeling_SQL/
│
├── 📂 docs/
│   └── 📂 images/
│       ├── 📊 executive-sales-overview.png      # Full executive dashboard canvas preview
│       └── 📈 monthly-merchandise-revenue.png    # Featured monthly revenue YoY trend visual
│
├── 📂 migrations/
│   ├── 🧩 01_patch_dim_customer_grain.sql       # Remodels customer to unique individual grain
│   ├── 📅 02_patch_dim_date_continuity.sql      # Rebuilds 1,096-day gapless calendar dimension
│   └── 🌐 03_patch_dim_product_english.sql      # Implements defensive English category mappings
│
├── 📂 powerbi/
│   ├── 📊 ecommercereport.pbix                  # Production Power BI dashboard report
│   └── 🎨 Executive_Theme.json                  # Soft-slate custom theme specification
│
├── 📄 01_data_exploration.sql                   # Database exploration and catalog profiling
├── 📄 02_data_quality.sql                       # Integrity tests and anomaly audits
├── 📄 03_business_analysis.sql                  # Business KPIs, AOV, and carrier SLA compliance
├── 📄 04_advanced_sql.sql                       # Window functions, rankings, and LAG analysis
├── 📄 05_olap_modeling.sql                      # Kimball star schema construction
├── ⚖️ LICENSE                                   # MIT License
└── 📘 README.md                                 # Portfolio presentation & technical documentation
```

---

# 🔗 Explore the Project

<div align="center">

### Ready to inspect the analytics and dashboard?

<br>

<a href="powerbi/ecommercereport.pbix">
  <img src="https://img.shields.io/badge/📊%20DOWNLOAD%20POWER%20BI%20REPORT-F2C811?style=for-the-badge&logoColor=000000" alt="Download Report">
</a>
&nbsp;
<a href="https://nirajbasnet.com.np/blog/olist-ecommerce-sql-analytics-and-olap-modeling/">
  <img src="https://img.shields.io/badge/📄%20READ%20CASE%20STUDY-7C3AED?style=for-the-badge&logoColor=white" alt="Read Case Study">
</a>
&nbsp;
<a href="05_olap_modeling.sql">
  <img src="https://img.shields.io/badge/🔎%20EXPLORE%20SQL%20CODE-4479A1?style=for-the-badge&logoColor=white" alt="Explore SQL">
</a>

<br><br>

### 🛒 E-Commerce Analytics · 📊 Power BI · 🗄️ MySQL 8.0 · 🐳 Docker · 🧱 Kimball Star Schema · 💡 Data Storytelling

<br>

**Built by Niraj Basnet**  
[Portfolio](https://nirajbasnet.com.np/) &nbsp;·&nbsp; [LinkedIn](https://www.linkedin.com/in/nirajbasnet009) &nbsp;·&nbsp; [GitHub](https://github.com/nirajbasnet009)

<br>

<a href="#-olist-brazilian-e-commerce-analytics--dimensional-modeling">⬆️ Back to top</a>

</div>
