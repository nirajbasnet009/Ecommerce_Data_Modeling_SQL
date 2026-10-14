
-- ============================================================
-- PROJECT: Olist Brazilian E-Commerce SQL Analysis
-- ============================================================
-- Author: Niraj Basnet
-- Database: ecommerce_db
-- DBMS: MySQL (Docker)
-- Dataset: Olist Brazilian E-Commerce Public Dataset
-- Source: Kaggle
-- File: 02_data_quality.sql
--
-- PURPOSE:
-- Assess the quality of the Olist e-commerce dataset by
-- identifying missing values, duplicate records, invalid
-- data, and inconsistencies across related tables.
--
-- ============================================================

USE ecommerce_db;


-- ============================================================
-- PHASE 2: DATA QUALITY & CLEANING
-- ============================================================

-- SECTION 1: MISSING DATA
-- ============================================================



-- Q11: How many customer records have missing location data?
SELECT 
     COUNT(*) AS customers_with_missing_location
FROM olist_customers_dataset
WHERE customer_zip_code_prefix IS NULL
      OR customer_city IS NULL
      OR customer_state IS NULL;

-- Are there any duplicate customer IDs in the Customers table?
SELECT
	 customer_id,
	 COUNT(*) AS occerance
FROM olist_customers_dataset
GROUP BY customer_id
HAVING occerance > 1
ORDER BY occerance DESC;
    
    
-- Q13: Are there any duplicate order IDs in the Orders table?
SELECT
	 order_id,
	 COUNT(*) AS occerance
FROM olist_orders_dataset
GROUP BY order_id
HAVING occerance > 1
ORDER BY occerance DESC;


-- How many orders have a delivery date earlier than their purchase date?
SELECT
      COUNT(*) AS invalid_delivery_dates
FROM olist_orders_dataset
WHERE order_purchase_timestamp > order_delivered_customer_date;


-- How many orders have been canceled, and what percentage of all orders do they represent?
SELECT 
     COUNT(*) AS total_orders, 
     SUM(CASE 
             WHEN order_status = 'canceled' THEN 1 
             ELSE 0 
		 END) AS total_cancelled_orders,
	 ROUND(SUM(CASE 
                    WHEN order_status = 'canceled' THEN 1 
                    ELSE 0 
				END) * 100 / COUNT(*),
                2 
	 ) AS cancellation_rate_pct
FROM olist_orders_dataset;
     
     

-- How many products have missing category, weight, or dimension information?
SELECT
      SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS missing_category,
	  SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS missing_weight,
	  SUM(CASE WHEN product_height_cm IS NULL
					 OR product_length_cm IS NULL
					 OR product_width_cm IS NULL THEN 1 ELSE 0 END)
	  AS missing_dimensions,
      COUNT(*)
FROM olist_products_dataset;


-- How many payment records have an invalid payment amount?
SELECT
     COUNT(*) AS invalid_payment
FROM olist_order_payments_dataset
WHERE payment_value <= 0;


-- -- Q18: Summarize missing, zero, and negative payment amounts.
SELECT 
     COUNT(*) AS total_payments,
     SUM(CASE WHEN payment_value = 0 THEN 1 ELSE 0 END) AS zero_payments,
	 SUM(CASE WHEN payment_value < 0 THEN 1 ELSE 0 END) AS negative_payments,
	 SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) as missing_payments
FROM olist_order_payments_dataset;
