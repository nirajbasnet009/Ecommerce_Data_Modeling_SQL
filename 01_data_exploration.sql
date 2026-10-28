-- ============================================================
-- PROJECT: Olist Brazilian E-Commerce SQL Analysis
-- ============================================================
-- Author: Niraj Basnet
-- Database: ecommerce_db
-- DBMS: MySQL (Docker)
-- Dataset: Olist Brazilian E-Commerce Public Dataset
-- Source: Kaggle
-- File: 01_data_exploration.sql
--
-- PURPOSE:
-- Explore the Olist e-commerce dataset to understand its
-- structure, record counts, customer activity, and order
-- statuses before performing data quality checks and analysis.
-- ============================================================

USE ecommerce_db;

-- ============================================================
-- SECTION 1: DATABASE OVERVIEW (Q1 - Q10)
-- ============================================================

-- Q1: How many records are stored in each of the nine tables?
SELECT
    'customers' AS table_name,
    COUNT(*) AS total_rows
FROM olist_customers_dataset

UNION ALL

SELECT
    'orders',
    COUNT(*)
FROM olist_orders_dataset

UNION ALL

SELECT
    'order_items',
    COUNT(*)
FROM olist_order_items_dataset

UNION ALL

SELECT
    'products',
    COUNT(*)
FROM olist_products_dataset

UNION ALL

SELECT
    'payments',
    COUNT(*)
FROM olist_order_payments_dataset

UNION ALL

SELECT
    'sellers',
    COUNT(*)
FROM olist_sellers_dataset

UNION ALL

SELECT
    'reviews',
    COUNT(*)
FROM olist_order_reviews_dataset

UNION ALL

SELECT
    'geolocation',
    COUNT(*)
FROM olist_geolocation_dataset

UNION ALL

SELECT
    'category_translation',
    COUNT(*)
FROM product_category_name_translation

ORDER BY
    total_rows DESC;


-- Q2: How many unique customers are in the Olist dataset?
SELECT
    COUNT(DISTINCT customer_unique_id) AS unique_customers_count
FROM olist_customers_dataset;


-- Q3: How many different order statuses exist in the dataset?
SELECT
    COUNT(DISTINCT order_status) AS total_order_statuses
FROM olist_orders_dataset;


-- Q4: How many orders belong to each order status?
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM olist_orders_dataset
GROUP BY
    order_status
ORDER BY
    total_orders DESC;


-- Q5: Which 10 Brazilian states have the most customer records in the Olist dataset?
SELECT 
    customer_state, 
    COUNT(*) AS total_customers 
FROM olist_customers_dataset 
GROUP BY
    customer_state 
ORDER BY
    total_customers DESC 
LIMIT 10;


-- Q6: Which 10 product categories contain the most products?
SELECT
    product_category_name,
    COUNT(*) AS total_products
FROM olist_products_dataset
GROUP BY
    product_category_name
ORDER BY
    total_products DESC
LIMIT 10;


-- Q7: How many products have no category assigned?
SELECT
    COUNT(*) AS products_without_category
FROM olist_products_dataset 
WHERE product_category_name IS NULL;


-- Q8: How many products have missing weight information?
SELECT
    COUNT(*) AS products_missing_weight
FROM olist_products_dataset 
WHERE product_weight_g IS NULL;


-- Q9: How many products have a weight of zero or less?
SELECT
    COUNT(*) AS products_invalid_weight
FROM olist_products_dataset 
WHERE product_weight_g = 0
   OR product_weight_g < 0;


-- Q10: What are the minimum, maximum, and average product weights in the Olist dataset?
SELECT 
    MIN(product_weight_g) AS min_weight_g,
    MAX(product_weight_g) AS max_weight_g,
    AVG(product_weight_g) AS avg_weight_g
FROM olist_products_dataset;
