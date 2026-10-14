# Olist Brazilian E-Commerce SQL Analytics & Data Quality

A SQL-based data analytics and data quality project analyzing more than 100,000 real customer orders from the Olist Brazilian E-Commerce public dataset.

## Database Architecture
- DBMS: MySQL running inside a Docker container
- Database Name: `ecommerce_db`
- Data Scope: 9 relational tables modeling customers, orders, order items, products, payments, sellers, reviews, geolocation, and category translations.

## Project Structure
- `01_data_exploration.sql`: Database overview, record counts using `UNION ALL`, order status distribution, and product catalog profiling.
- `02_data_quality.sql`: Data validation test suite checking for duplicate primary keys, null values, invalid delivery timestamps, order cancellation rates, and negative payment anomalies.
- `03_business_analysis.sql`: Multi-table joins and Common Table Expressions (CTEs) calculating Average Order Value (AOV), top product categories, seller performance, and on-time delivery percentages.
- `04_advanced_sql.sql`: Advanced SQL queries utilizing window functions (`ROW_NUMBER`, `RANK`, `DENSE_RANK`), sales rankings, and customer order sequences.

## Key SQL Concepts Demonstrated
- Multi-table `INNER JOIN` operations linking up to three tables
- Common Table Expressions (`WITH` CTEs) for modular business calculations
- Conditional aggregations (`SUM(CASE WHEN...)`)
- Date and time calculations (`TIMESTAMPDIFF`, `DATE`)
- Window functions (`ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`)
- Data hygiene and integrity testing

## How to Run
1. Start the MySQL Docker container:
   ```bash
   docker run --name ecommerce_mysql -p 3307:3306 -e MYSQL_ROOT_PASSWORD=your_password -d mysql:latest
   ```
2. Load the Olist datasets into `ecommerce_db`.
3. Run the SQL scripts in numerical order (`01` through `04`).
