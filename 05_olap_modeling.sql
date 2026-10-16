-- ============================================================
-- PROJECT: Olist Brazilian E-Commerce SQL Analysis
-- ============================================================
-- Author: Niraj Basnet
-- Database: ecommerce_db
-- DBMS: MySQL (Docker)
-- Dataset: Olist Brazilian E-Commerce Public Dataset
-- Source: Kaggle
-- File: 05_olap_modeling.sql
--
-- PURPOSE:
-- Design and implement an analytical star schema for OLAP.
-- Construct the central sales fact table (fact_sales) at the
-- order-item grain, perform data type conversions, validate
-- key constraints, and reconcile sales totals against source data.
-- ============================================================

USE ecommerce_db;

-- ============================================================
-- SECTION 5: OLAP DIMENSIONAL MODELING (Q43 - Q50)
-- STATUS: In Progress
-- ============================================================

-- ------------------------------------------------------------
-- Q43: Build the initial sales fact table (fact_sales) for delivered orders
-- ------------------------------------------------------------
DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp AS purchase_date,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value
FROM olist_orders_dataset o 
INNER JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id 
WHERE o.order_status = 'delivered';


-- ------------------------------------------------------------
-- STEP 1: Verify Composite Primary Key Uniqueness (order_id, order_item_id)
-- ------------------------------------------------------------
SELECT 
    order_id,
    order_item_id,
    COUNT(*) AS duplicate_count
FROM fact_sales
GROUP BY 
    order_id,
    order_item_id
HAVING 
    COUNT(*) > 1;


-- ------------------------------------------------------------
-- STEP 2: Check for Null Values in Primary Key Columns
-- ------------------------------------------------------------
SELECT 
    COUNT(*) AS null_key_count
FROM fact_sales
WHERE order_id IS NULL 
   OR order_item_id IS NULL;


-- ------------------------------------------------------------
-- STEP 3: Profile String Field Lengths for Storage Optimization
-- ------------------------------------------------------------
SELECT
    MAX(CHAR_LENGTH(order_id)) AS max_order_id_length,
    MAX(CHAR_LENGTH(customer_id)) AS max_customer_id_length,
    MAX(CHAR_LENGTH(product_id)) AS max_product_id_length,
    MAX(CHAR_LENGTH(seller_id)) AS max_seller_id_length
FROM fact_sales;


-- ------------------------------------------------------------
-- STEP 4: Validate Timestamp Format and Data Integrity
-- ------------------------------------------------------------
SELECT DISTINCT
    purchase_date
FROM fact_sales
LIMIT 10;

SELECT
    COUNT(*) AS invalid_dates
FROM fact_sales
WHERE purchase_date IS NULL
   OR STR_TO_DATE(purchase_date, '%Y-%m-%d %H:%i:%s') IS NULL;


-- ------------------------------------------------------------
-- STEP 5: Validate Financial Field Precision and Null Values
-- ------------------------------------------------------------
SELECT 
    COUNT(*) AS imprecise_decimal_count
FROM fact_sales
WHERE price <> ROUND(price, 2) 
   OR freight_value <> ROUND(freight_value, 2);

SELECT 
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight
FROM fact_sales;

SELECT 
    COUNT(CASE WHEN price IS NULL THEN 1 END) AS missing_price_count,
    COUNT(CASE WHEN freight_value IS NULL THEN 1 END) AS missing_freight_count
FROM fact_sales;


-- ------------------------------------------------------------
-- STEP 6: Apply Production Schema Constraints and Data Types
-- ------------------------------------------------------------
ALTER TABLE fact_sales
    MODIFY COLUMN order_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN order_item_id INT NOT NULL,
    MODIFY COLUMN customer_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN product_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN seller_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN purchase_date DATETIME NOT NULL,
    MODIFY COLUMN price DECIMAL(12, 2) NOT NULL,
    MODIFY COLUMN freight_value DECIMAL(12, 2) NOT NULL;

DESCRIBE fact_sales;


-- ------------------------------------------------------------
-- STEP 7: Reconcile Fact Table Revenue with Raw Source Data
-- ------------------------------------------------------------
SELECT
    (SELECT SUM(price) FROM fact_sales) AS fact_total_sales,
    (SELECT ROUND(SUM(oi.price), 2)
     FROM olist_order_items_dataset oi
     INNER JOIN olist_orders_dataset o
         ON oi.order_id = o.order_id
     WHERE o.order_status = 'delivered') AS source_total_sales;


-- ------------------------------------------------------------
-- STEP 8: Synchronize Line Item Values with Source Table
-- ------------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

UPDATE fact_sales AS f
INNER JOIN olist_order_items_dataset AS oi
    ON f.order_id = oi.order_id
   AND f.order_item_id = oi.order_item_id
SET
    f.price = oi.price,
    f.freight_value = oi.freight_value;

SELECT
    SUM(price) AS total_verified_sales
FROM fact_sales;


-- ------------------------------------------------------------
-- STEP 9: Teardown / Recreation Utility
-- ------------------------------------------------------------
DROP TABLE IF EXISTS fact_sales;