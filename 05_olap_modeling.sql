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
-- ============================================================

-- Q43: Build the initial sales fact table (fact_sales) for delivered orders
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


-- Step 1: Verify Composite Primary Key Uniqueness (order_id, order_item_id)
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


-- Step 2: Check for Null Values in Primary Key Columns
SELECT 
    COUNT(*) AS null_key_count
FROM fact_sales
WHERE order_id IS NULL 
   OR order_item_id IS NULL;


-- Step 3: Profile String Field Lengths for Storage Optimization
SELECT
    MAX(CHAR_LENGTH(order_id)) AS max_order_id_length,
    MAX(CHAR_LENGTH(customer_id)) AS max_customer_id_length,
    MAX(CHAR_LENGTH(product_id)) AS max_product_id_length,
    MAX(CHAR_LENGTH(seller_id)) AS max_seller_id_length
FROM fact_sales;


-- Step 4: Validate Timestamp Format and Data Integrity
SELECT DISTINCT
    purchase_date
FROM fact_sales
LIMIT 10;

SELECT
    COUNT(*) AS invalid_dates
FROM fact_sales
WHERE purchase_date IS NULL
   OR STR_TO_DATE(purchase_date, '%Y-%m-%d %H:%i:%s') IS NULL;


-- Step 5: Validate Financial Field Precision and Null Values
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


-- Step 6: Apply Production Schema Constraints and Data Types
ALTER TABLE fact_sales
    ADD PRIMARY KEY (order_id, order_item_id),
    MODIFY COLUMN order_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN order_item_id INT NOT NULL,
    MODIFY COLUMN customer_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN product_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN seller_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN purchase_date DATETIME NOT NULL,
    MODIFY COLUMN price DECIMAL(12, 2) NOT NULL,
    MODIFY COLUMN freight_value DECIMAL(12, 2) NOT NULL;

DESCRIBE fact_sales;


-- Step 7: Reconcile Fact Table Revenue with Raw Source Data
SELECT
    (SELECT SUM(price) FROM fact_sales) AS fact_total_sales,
    (SELECT ROUND(SUM(oi.price), 2)
     FROM olist_order_items_dataset oi
     INNER JOIN olist_orders_dataset o
         ON oi.order_id = o.order_id
     WHERE o.order_status = 'delivered') AS source_total_sales;


-- Step 8: Synchronize Line Item Values with Source Table
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


-- Step 9: Teardown / Recreation Utility (Optional: run only to reset fact table)
-- DROP TABLE IF EXISTS fact_sales;


-- ============================================================
-- Q44: CREATE AND VALIDATE CUSTOMER DIMENSION TABLE
-- ============================================================

-- Step 1: Check source table structure
DESCRIBE olist_customers_dataset;


-- Step 2: Count total customers
SELECT
    COUNT(*) AS total_customers
FROM olist_customers_dataset;


-- Step 3: Check duplicate customer IDs
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM olist_customers_dataset
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Step 4: Check null customer IDs
SELECT
    COUNT(*) AS null_customer_count
FROM olist_customers_dataset
WHERE customer_id IS NULL;


-- Step 5: Check maximum ID lengths
SELECT
    MAX(CHAR_LENGTH(customer_id)) AS max_customer_id_length,
    MAX(CHAR_LENGTH(customer_unique_id)) AS max_unique_id_length
FROM olist_customers_dataset;


-- Step 6: Check maximum lengths of other columns
SELECT
    MAX(CHAR_LENGTH(customer_zip_code_prefix)) AS max_zip_length,
    MAX(CHAR_LENGTH(customer_city)) AS max_city_length,
    MAX(CHAR_LENGTH(customer_state)) AS max_state_length
FROM olist_customers_dataset;


-- Step 7: Check missing values
SELECT
    SUM(customer_unique_id IS NULL) AS null_unique_id,
    SUM(customer_zip_code_prefix IS NULL) AS null_zip,
    SUM(customer_city IS NULL) AS null_city,
    SUM(customer_state IS NULL) AS null_state
FROM olist_customers_dataset;


-- Step 8: Create dim_customer dimension table using CTAS
DROP TABLE IF EXISTS dim_customer;

CREATE TABLE dim_customer AS
SELECT
    CAST(customer_id AS CHAR(32)) AS customer_id,
    customer_unique_id AS customer_unique_id,
    customer_zip_code_prefix AS customer_zip_code_prefix,
    customer_city AS customer_city,
    customer_state AS customer_state
FROM olist_customers_dataset;

SELECT * FROM dim_customer LIMIT 10;

ALTER TABLE dim_customer
    ADD CONSTRAINT pk_dim_customer PRIMARY KEY (customer_id),
    MODIFY COLUMN customer_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN customer_unique_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN customer_zip_code_prefix VARCHAR(5) NOT NULL,
    MODIFY COLUMN customer_city VARCHAR(32) NOT NULL,
    MODIFY COLUMN customer_state CHAR(2) NOT NULL;

DESCRIBE dim_customer;
DESCRIBE fact_sales;

SELECT
    (SELECT COUNT(*) FROM dim_customer) AS dimension_rows,
    (SELECT COUNT(*) FROM olist_customers_dataset) AS source_rows;


-- ============================================================
-- Q45: CREATE AND VALIDATE PRODUCT DIMENSION TABLE
-- ============================================================

-- Step 1: Check source table structure
DESCRIBE olist_products_dataset;


-- Step 2: Count total products
SELECT COUNT(*) AS total_products
FROM olist_products_dataset;


-- Step 3: Check duplicate product IDs
SELECT COUNT(*) AS duplicate_product_count
FROM olist_products_dataset
GROUP BY product_id
HAVING COUNT(*) > 1;


-- Step 4: Check null product IDs
SELECT * FROM olist_products_dataset
WHERE product_id IS NULL;


-- Step 5: Check maximum ID lengths
SELECT MAX(CHAR_LENGTH(product_id)) AS max_product_id_length
FROM olist_products_dataset;


-- Step 6: Check maximum lengths of other columns
SELECT 
    MAX(CAST(product_name_lenght AS SIGNED)),
    MAX(CAST(product_description_lenght AS SIGNED)),
    MAX(CAST(product_photos_qty AS SIGNED)),
    MAX(CAST(product_weight_g AS SIGNED)),
    MAX(CAST(product_length_cm AS SIGNED)),
    MAX(CAST(product_height_cm AS SIGNED)),
    MAX(CAST(product_width_cm AS SIGNED)),
    MAX(CHAR_LENGTH(product_category_name))
FROM olist_products_dataset;


-- Step 7: Check missing values
SELECT 
    SUM(product_category_name IS NULL),
    SUM(product_name_lenght IS NULL),
    SUM(product_description_lenght IS NULL),
    SUM(product_photos_qty IS NULL),
    SUM(product_weight_g IS NULL),
    SUM(product_length_cm IS NULL),
    SUM(product_height_cm IS NULL),
    SUM(product_width_cm IS NULL)
FROM olist_products_dataset;

SELECT
    COUNT(*) AS invalid_weight_count
FROM olist_products_dataset
WHERE product_weight_g NOT REGEXP '^[0-9]+$';


-- Step 8: Check invalid numeric values
SELECT
    SUM(product_name_lenght NOT REGEXP '^[0-9]+$') AS invalid_name_length,
    SUM(product_description_lenght NOT REGEXP '^[0-9]+$') AS invalid_description_length,
    SUM(product_photos_qty NOT REGEXP '^[0-9]+$') AS invalid_photos,
    SUM(product_weight_g NOT REGEXP '^[0-9]+$') AS invalid_weight,
    SUM(product_length_cm NOT REGEXP '^[0-9]+$') AS invalid_length,
    SUM(product_height_cm NOT REGEXP '^[0-9]+$') AS invalid_height,
    SUM(product_width_cm NOT REGEXP '^[0-9]+$') AS invalid_width
FROM olist_products_dataset;


-- Step 9: Create dim_product dimension table using CTAS
DROP TABLE IF EXISTS dim_product;

CREATE TABLE dim_product AS
SELECT
    CAST(product_id AS CHAR(32)) AS product_id,
    product_category_name AS product_category_name,
    product_name_lenght AS product_name_length,
    product_description_lenght AS product_description_length,
    product_photos_qty AS product_photos_qty,
    product_weight_g AS product_weight_g,
    product_length_cm AS product_length_cm,
    product_height_cm AS product_height_cm,
    product_width_cm AS product_width_cm
FROM olist_products_dataset;

DESCRIBE dim_product;

ALTER TABLE dim_product
    MODIFY COLUMN product_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN product_category_name VARCHAR(50) NOT NULL,
    MODIFY COLUMN product_name_length INT NOT NULL,
    MODIFY COLUMN product_description_length INT NOT NULL,
    MODIFY COLUMN product_photos_qty INT NOT NULL,
    MODIFY COLUMN product_weight_g INT NOT NULL,
    MODIFY COLUMN product_length_cm INT NOT NULL,
    MODIFY COLUMN product_height_cm INT NOT NULL,
    MODIFY COLUMN product_width_cm INT NOT NULL,
    ADD PRIMARY KEY (product_id);


-- Step 10: Validate rows against source
SELECT
    (SELECT COUNT(*) FROM dim_product) AS dimension_rows,
    (SELECT COUNT(*) FROM olist_products_dataset) AS source_rows;


-- Step 11: Check duplicate IDs
SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM dim_product
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS empty_product_id_count 
FROM dim_product
WHERE TRIM(product_id) = '';


-- Step 12: Check NULL and empty values in dim_product
SELECT
    COUNT(*) AS total_rows,

    SUM(product_id IS NULL) AS null_product_id,
    SUM(TRIM(product_id) = '') AS empty_product_id,

    SUM(product_category_name IS NULL) AS null_category,
    SUM(product_name_length IS NULL) AS null_name_length,
    SUM(product_description_length IS NULL) AS null_description_length,
    SUM(product_photos_qty IS NULL) AS null_photos,
    SUM(product_weight_g IS NULL) AS null_weight,
    SUM(product_length_cm IS NULL) AS null_length,
    SUM(product_height_cm IS NULL) AS null_height,
    SUM(product_width_cm IS NULL) AS null_width
FROM dim_product;


-- ============================================================
-- Q46: CREATE AND VALIDATE SELLER DIMENSION TABLE
-- ============================================================

-- Step 1: Check source table structure
DESCRIBE olist_sellers_dataset;


-- Step 2: Count total sellers
SELECT
    COUNT(*) AS total_sellers
FROM olist_sellers_dataset;


-- Step 3: Check duplicate seller IDs
SELECT
    seller_id,
    COUNT(*) AS duplicate_count
FROM olist_sellers_dataset
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- Step 4: Check null seller IDs
SELECT
    COUNT(*) AS null_seller_id
FROM olist_sellers_dataset
WHERE seller_id IS NULL;


-- Step 5: Check maximum character lengths
SELECT
    MAX(CHAR_LENGTH(seller_id)) AS max_seller_id_length,
    MAX(CHAR_LENGTH(seller_zip_code_prefix)) AS max_zip_length,
    MAX(CHAR_LENGTH(seller_city)) AS max_city_length,
    MAX(CHAR_LENGTH(seller_state)) AS max_state_length
FROM olist_sellers_dataset;


-- Step 6: Check missing values in all columns
SELECT
    SUM(seller_id IS NULL) AS null_seller_id,
    SUM(seller_zip_code_prefix IS NULL) AS null_zip,
    SUM(seller_city IS NULL) AS null_city,
    SUM(seller_state IS NULL) AS null_state
FROM olist_sellers_dataset;


-- Step 7: Check empty strings
SELECT
    SUM(TRIM(seller_id) = '') AS empty_seller_id,
    SUM(TRIM(seller_zip_code_prefix) = '') AS empty_zip,
    SUM(TRIM(seller_city) = '') AS empty_city,
    SUM(TRIM(seller_state) = '') AS empty_state
FROM olist_sellers_dataset;


-- Step 8: Check zip code format
SELECT
    COUNT(*) AS invalid_zip_count
FROM olist_sellers_dataset
WHERE seller_zip_code_prefix IS NOT NULL
  AND seller_zip_code_prefix NOT REGEXP '^[0-9]{5}$';


-- Step 9: Check state code format
SELECT
    COUNT(*) AS invalid_state_count
FROM olist_sellers_dataset
WHERE seller_state IS NOT NULL
  AND seller_state NOT REGEXP '^[A-Z]{2}$';


-- Step 10: Create dim_seller dimension table using CTAS
DROP TABLE IF EXISTS dim_seller;

CREATE TABLE dim_seller AS
SELECT 
    CAST(seller_id AS CHAR(32)) AS seller_id,
    seller_zip_code_prefix AS seller_zip_code_prefix,
    seller_city AS seller_city,
    seller_state AS seller_state
FROM olist_sellers_dataset;

ALTER TABLE dim_seller
    ADD PRIMARY KEY (seller_id),
    MODIFY COLUMN seller_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN seller_zip_code_prefix VARCHAR(5) NOT NULL,
    MODIFY COLUMN seller_city VARCHAR(50) NOT NULL,
    MODIFY COLUMN seller_state VARCHAR(2) NOT NULL;

DESCRIBE dim_seller;


-- Step 11: Row comparison with source
SELECT
    (SELECT COUNT(*) FROM dim_seller) AS dimension_rows,
    (SELECT COUNT(*) FROM olist_sellers_dataset) AS source_rows;


-- ============================================================
-- Q47: CREATE AND VALIDATE DATE DIMENSION TABLE
-- ============================================================

-- Step 1: Check source table structure
DESCRIBE fact_sales;


-- Step 2: Check total sales records
SELECT
    COUNT(*) AS total_sales_records
FROM fact_sales;


-- Step 3: Check null purchase dates
SELECT
    COUNT(*) AS null_purchase_dates
FROM fact_sales
WHERE purchase_date IS NULL;


-- Step 4: Check minimum and maximum purchase dates
SELECT
    MIN(DATE(purchase_date)) AS first_purchase_date,
    MAX(DATE(purchase_date)) AS last_purchase_date
FROM fact_sales;


-- Step 5: Count unique purchase dates
SELECT
    COUNT(DISTINCT DATE(purchase_date)) AS unique_dates
FROM fact_sales;


-- Step 6: Check date key generation
SELECT DISTINCT
    CAST(
        DATE_FORMAT(purchase_date, '%Y%m%d')
        AS UNSIGNED
    ) AS date_key,
    DATE(purchase_date) AS full_date
FROM fact_sales
ORDER BY full_date
LIMIT 10;


-- Step 7: Check date key uniqueness
SELECT
    CAST(
        DATE_FORMAT(purchase_date, '%Y%m%d')
        AS UNSIGNED
    ) AS date_key,
    COUNT(DISTINCT DATE(purchase_date)) AS distinct_dates
FROM fact_sales
GROUP BY date_key
HAVING COUNT(DISTINCT DATE(purchase_date)) > 1;


-- Step 8: Check date components
SELECT DISTINCT
    DATE(purchase_date) AS full_date,
    DAY(purchase_date) AS day,
    MONTH(purchase_date) AS month,
    QUARTER(purchase_date) AS quarter,
    YEAR(purchase_date) AS year
FROM fact_sales
ORDER BY full_date
LIMIT 10;


-- Step 9: Create dim_date dimension table
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    date_key INT NOT NULL PRIMARY KEY,
    full_purchase_date DATE NOT NULL,
    day TINYINT NOT NULL,
    month TINYINT NOT NULL,
    quarter TINYINT NOT NULL,
    year SMALLINT NOT NULL
) AS
SELECT DISTINCT
    CAST(DATE_FORMAT(purchase_date, '%Y%m%d') AS UNSIGNED) AS date_key,
    DATE(purchase_date) AS full_purchase_date,
    DAY(purchase_date) AS day,
    MONTH(purchase_date) AS month,
    QUARTER(purchase_date) AS quarter,
    YEAR(purchase_date) AS year
FROM fact_sales;

DESCRIBE dim_date;


-- Step 10: Validate dim_date rows
SELECT
    (SELECT COUNT(*) FROM dim_date) AS dim_date_rows,
    (SELECT COUNT(DISTINCT DATE(purchase_date)) FROM fact_sales) AS unique_purchase_dates;


-- Step 11: Join verification
SELECT 
    order_id, customer_id, purchase_date, order_item_id, product_id, seller_id, price, freight_value
FROM fact_sales f
INNER JOIN dim_date
    ON DATE(f.purchase_date) = full_purchase_date;


-- Step 12: Final validation
SELECT 
    (SELECT COUNT(*) FROM fact_sales) AS original_sales,
    (SELECT COUNT(*)
     FROM fact_sales f
     INNER JOIN dim_date d
         ON DATE(f.purchase_date) = full_purchase_date) AS joined_sales;


-- ============================================================
-- Q48: POPULATE AND VALIDATE STAR SCHEMA FOREIGN KEYS
-- ============================================================

-- Step 1: Add date_key column to fact_sales
ALTER TABLE fact_sales
ADD COLUMN date_key INT;


-- Step 2: Populate date foreign key
SET SQL_SAFE_UPDATES = 0;

UPDATE fact_sales
SET date_key = CAST(
    DATE_FORMAT(purchase_date, '%Y%m%d') AS UNSIGNED
);


-- Step 3: Add date foreign key constraint
ALTER TABLE fact_sales
MODIFY date_key INT NOT NULL,
ADD CONSTRAINT fk_sales_date
FOREIGN KEY (date_key)
REFERENCES dim_date(date_key);

DESCRIBE fact_sales;
SHOW CREATE TABLE fact_sales;


-- Step 4: Validate customer relationship
SELECT
    COUNT(*) AS unmatched_customers
FROM fact_sales AS f
LEFT JOIN dim_customer AS c
    ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Step 5: Add customer foreign key constraint
ALTER TABLE fact_sales
ADD CONSTRAINT fk_sales_customer
FOREIGN KEY (customer_id)
REFERENCES dim_customer(customer_id);

SHOW CREATE TABLE fact_sales;


-- Step 6: Validate product relationship
SELECT COUNT(*) AS unmatched_products
FROM fact_sales AS f
LEFT JOIN dim_product AS p
    ON f.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Step 6A: Check missing products in original dataset
SELECT
    COUNT(*) AS unmatched_original_products
FROM fact_sales AS f
LEFT JOIN olist_products_dataset AS p
    ON f.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Step 6B: Identify missing product IDs
SELECT
    f.product_id,
    COUNT(*) AS affected_sales
FROM fact_sales AS f
LEFT JOIN olist_products_dataset AS p
    ON f.product_id = p.product_id
WHERE p.product_id IS NULL
GROUP BY f.product_id
ORDER BY affected_sales DESC
LIMIT 20;


-- Step 6C: Inspect missing product ID
SELECT
    product_id,
    LENGTH(product_id) AS id_length,
    HEX(product_id) AS id_hex
FROM fact_sales
WHERE product_id = '5a848e4ab52fd5445cdc07aab1c40e48'
LIMIT 1;


-- Step 6D: Count unique missing products
SELECT
    COUNT(*) AS affected_sales,
    COUNT(DISTINCT f.product_id) AS unique_missing_products
FROM fact_sales AS f
LEFT JOIN olist_products_dataset AS p
    ON f.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Step 6E: Check original product ID completeness
SELECT
    COUNT(*) AS total_products,
    COUNT(product_id) AS non_null_product_ids,
    COUNT(DISTINCT product_id) AS unique_product_ids
FROM olist_products_dataset;


-- Step 6F: Compare product ID formats
SELECT
    'fact_sales' AS source_table,
    MIN(LENGTH(product_id)) AS min_length,
    MAX(LENGTH(product_id)) AS max_length
FROM fact_sales

UNION ALL

SELECT
    'olist_products_dataset' AS source_table,
    MIN(LENGTH(product_id)) AS min_length,
    MAX(LENGTH(product_id)) AS max_length
FROM olist_products_dataset;


-- Step 6G: Check product IDs for hidden spaces
SELECT
    'fact_sales' AS source_table,
    COUNT(*) AS ids_with_spaces
FROM fact_sales
WHERE product_id <> TRIM(product_id)

UNION ALL

SELECT
    'olist_products_dataset' AS source_table,
    COUNT(*) AS ids_with_spaces
FROM olist_products_dataset
WHERE product_id <> TRIM(product_id);


-- Step 6H: Verify a missing product in the original table
SELECT *
FROM olist_products_dataset
WHERE product_id = '5a848e4ab52fd5445cdc07aab1c40e48';


-- Step 6I: Compare source and dimension product counts
SELECT
    (SELECT COUNT(*) FROM olist_products_dataset) AS source_products,
    (SELECT COUNT(*) FROM dim_product) AS dimension_products,
    (SELECT COUNT(*) FROM fact_sales) AS sales_records;


-- Step 6J: Check missing product IDs in dimension
SELECT
    COUNT(*) AS missing_in_dimension
FROM olist_products_dataset AS p
LEFT JOIN dim_product AS d
    ON p.product_id = d.product_id
WHERE d.product_id IS NULL;


-- Step 6K: Check unmatched products in original order items
SELECT
    COUNT(*) AS unmatched_order_items
FROM olist_order_items_dataset AS oi
LEFT JOIN olist_products_dataset AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Step 6L: Insert missing products into dim_product as 'Unknown'
-- While building the dimensional model, 
-- I discovered that 611 products in the source dataset had missing catalog metadata. 
-- Rather than dropping them and underreporting ,000 in sales, 
-- I followed Kimball dimensional standards by modeling them as 'Unknown' categories to preserve 100% financial integrity in the fact table.
INSERT INTO dim_product (
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT 
    DISTINCT
    oi.product_id,
    'Unknown' AS product_category_name,
    0 AS product_name_length,
    0 AS product_description_length,
    0 AS product_photos_qty,
    0 AS product_weight_g,
    0 AS product_length_cm,
    0 AS product_height_cm,
    0 AS product_width_cm
FROM olist_order_items_dataset oi
LEFT JOIN dim_product dp 
    ON oi.product_id = dp.product_id
WHERE dp.product_id IS NULL;

-- 1. Check total rows: should now be 32,951 (32,340 + 611)
SELECT COUNT(*) AS total_products FROM dim_product;

-- 2. Check missing order items: should now return 0
SELECT COUNT(*) AS unmapped_order_items
FROM olist_order_items_dataset oi
LEFT JOIN dim_product dp 
    ON oi.product_id = dp.product_id
WHERE dp.product_id IS NULL;

-- 3. Check fact_sales revenue match: should now return zsh lost revenue
SELECT 
    COUNT(*) AS dropped_fact_rows,
    ROUND(COALESCE(SUM(f.price), 0), 2) AS lost_revenue
FROM fact_sales f
LEFT JOIN dim_product dp 
    ON f.product_id = dp.product_id
WHERE dp.product_id IS NULL;


-- Step 6M: Add product foreign key constraint
ALTER TABLE fact_sales
ADD CONSTRAINT fk_sales_product
FOREIGN KEY (product_id)
REFERENCES dim_product(product_id);


-- Step 7: Validate seller relationship
SELECT
    COUNT(*) AS unmatched_sellers
FROM fact_sales AS f
LEFT JOIN dim_seller AS s
    ON f.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- Step 8: Add seller foreign key constraint
ALTER TABLE fact_sales
ADD CONSTRAINT fk_sales_seller
FOREIGN KEY (seller_id)
REFERENCES dim_seller(seller_id);

DESCRIBE fact_sales;
SHOW CREATE TABLE fact_sales;


-- ============================================================
-- Q49: PERFORM OLAP ANALYSIS USING THE STAR SCHEMA
-- ============================================================

-- Step 1: Quarterly sales analysis
SELECT 
    d.year,
    d.quarter,
    SUM(f.price) AS total_sales
FROM fact_sales f
INNER JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY 
    year, 
    quarter
ORDER BY 
    year, 
    quarter;


-- Step 2: Analyze monthly sales using the star schema
SELECT 
    d.year,
    d.month,
    SUM(f.price) AS total_sales
FROM fact_sales f
INNER JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY 
    year, 
    month
ORDER BY 
    year, 
    month;


-- Step 3: Analyze quarterly sales by product category
SELECT 
    d.year,
    d.quarter,
    p.product_category_name,
    SUM(f.price) AS total_sales
FROM fact_sales f
INNER JOIN dim_date d
    ON f.date_key = d.date_key
INNER JOIN dim_product p
    ON f.product_id = p.product_id
GROUP BY 
    year, 
    quarter, 
    product_category_name
ORDER BY 
    year, 
    quarter, 
    total_sales DESC;


-- Step 4: Analyze quarterly sales by customer state
SELECT 
    d.year,
    d.quarter,
    c.customer_state,
    SUM(f.price) AS total_sales
FROM fact_sales f
INNER JOIN dim_date d
    ON f.date_key = d.date_key
INNER JOIN dim_customer c
    ON f.customer_id = c.customer_id
GROUP BY 
    year, 
    quarter, 
    customer_state
ORDER BY 
    year, 
    quarter, 
    total_sales DESC;


-- Step 5: Analyze quarterly sales by seller state
SELECT 
    d.year,
    d.quarter,
    s.seller_state,
    SUM(f.price) AS total_sales
FROM fact_sales f
INNER JOIN dim_date d
    ON f.date_key = d.date_key
INNER JOIN dim_seller s
    ON f.seller_id = s.seller_id
GROUP BY 
    year, 
    quarter, 
    seller_state
ORDER BY 
    year, 
    quarter, 
    total_sales DESC;


-- ============================================================
-- Q50: VERIFY STAR SCHEMA INTEGRITY ACROSS ALL DIMENSIONS
-- ============================================================

-- Step 1: Validate all star schema relationships
SELECT 
    COUNT(*) AS total_joined_records
FROM fact_sales f
INNER JOIN dim_date d
    ON f.date_key = d.date_key
INNER JOIN dim_seller s
    ON f.seller_id = s.seller_id
INNER JOIN dim_product p
    ON f.product_id = p.product_id
INNER JOIN dim_customer c
    ON f.customer_id = c.customer_id;

SELECT COUNT(*) AS total_fact_records FROM fact_sales;


-- Step 2: Validate revenue consistency
SELECT 
    SUM(f.price) AS joined_total_sales
FROM fact_sales f
INNER JOIN dim_date d
    ON f.date_key = d.date_key
INNER JOIN dim_seller s
    ON f.seller_id = s.seller_id
INNER JOIN dim_product p
    ON f.product_id = p.product_id
INNER JOIN dim_customer c
    ON f.customer_id = c.customer_id;

SELECT SUM(price) AS fact_total_sales FROM fact_sales;


-- Step 3: Validate shipping cost consistency
SELECT 
    SUM(f.freight_value) AS joined_total_freight
FROM fact_sales f
INNER JOIN dim_date d
    ON f.date_key = d.date_key
INNER JOIN dim_seller s
    ON f.seller_id = s.seller_id
INNER JOIN dim_product p
    ON f.product_id = p.product_id
INNER JOIN dim_customer c
    ON f.customer_id = c.customer_id;

SELECT SUM(freight_value) AS fact_total_freight FROM fact_sales;
