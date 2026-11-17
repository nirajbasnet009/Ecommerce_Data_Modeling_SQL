-- ====================================================================
-- MIGRATION: 01_patch_dim_customer_grain.sql
-- PURPOSE: Remodel dim_customer and fact_sales from transaction token 
--          (customer_id) to unique entity grain (customer_unique_id).
-- TARGET: ecommerce_db (MySQL 8.0)
-- AUTHOR: Niraj Basnet
-- ====================================================================

USE ecommerce_db;

-- --------------------------------------------------------------------
-- 1. Add customer_unique_id column to fact_sales
-- Purpose: fact_sales currently only links to checkout tokens (customer_id).
--          We add customer_unique_id to connect sales directly to real human entities.
-- --------------------------------------------------------------------
ALTER TABLE fact_sales 
ADD COLUMN customer_unique_id VARCHAR(32) AFTER customer_id;

-- --------------------------------------------------------------------
-- 2. Backfill customer_unique_id into fact_sales
-- Purpose: Look up each order's customer_id in olist_customers_dataset
--          and copy over the corresponding true person identifier (customer_unique_id).
-- --------------------------------------------------------------------
UPDATE fact_sales f
INNER JOIN olist_customers_dataset c 
    ON f.customer_id = c.customer_id
SET f.customer_unique_id = c.customer_unique_id;

-- --------------------------------------------------------------------
-- 3. Enforce NOT NULL constraint on customer_unique_id
-- Purpose: In Kimball dimensional modeling, foreign keys in a fact table
--          must never be NULL to avoid orphaned sales records in BI joins.
-- --------------------------------------------------------------------
ALTER TABLE fact_sales 
MODIFY COLUMN customer_unique_id VARCHAR(32) NOT NULL;

-- --------------------------------------------------------------------
-- 4. Drop legacy foreign key constraint on fact_sales
-- Purpose: Remove the old relationship linking fact_sales to customer_id
--          so we can safely rebuild dim_customer without foreign key lock errors.
-- --------------------------------------------------------------------
ALTER TABLE fact_sales 
DROP FOREIGN KEY fk_sales_customer;

-- --------------------------------------------------------------------
-- 5. Rebuild dim_customer at the true entity grain
-- Purpose: Deduplicate customers so each real human being gets exactly 
--          one row (96,096 rows total) with their latest address.
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS dim_customer;

CREATE TABLE dim_customer AS
WITH ranked_customers AS (
    SELECT 
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        ROW_NUMBER() OVER(
            PARTITION BY customer_unique_id 
            ORDER BY customer_id DESC
        ) AS rn
    FROM olist_customers_dataset
)
SELECT 
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM ranked_customers
WHERE rn = 1;

-- --------------------------------------------------------------------
-- 6. Enforce Primary Key and clean data types on dim_customer
-- Purpose: Lock customer_unique_id as the unique identifier and ensure
--          strict column sizing and NOT NULL constraints.
-- --------------------------------------------------------------------
ALTER TABLE dim_customer
    ADD PRIMARY KEY (customer_unique_id),
    MODIFY COLUMN customer_unique_id VARCHAR(32) NOT NULL,
    MODIFY COLUMN customer_zip_code_prefix VARCHAR(5) NOT NULL,
    MODIFY COLUMN customer_city VARCHAR(32) NOT NULL,
    MODIFY COLUMN customer_state CHAR(2) NOT NULL;

-- --------------------------------------------------------------------
-- 7. Add new foreign key constraint from fact_sales to dim_customer
-- Purpose: Establish strict referential integrity between fact_sales and 
--          dim_customer using the real customer identifier (customer_unique_id).
-- --------------------------------------------------------------------
ALTER TABLE fact_sales
ADD CONSTRAINT fk_sales_customer_unique
FOREIGN KEY (customer_unique_id)
REFERENCES dim_customer(customer_unique_id);

-- --------------------------------------------------------------------
-- 8. Post-Migration Verification & Assertions
-- Purpose: Programmatically prove that the table counts match expected 
--          baselines and zero orphaned records exist.
-- --------------------------------------------------------------------

-- Test 1: Verify dim_customer has exactly 96,096 unique customer entities
SELECT 
    COUNT(*) AS total_dim_rows,
    CASE 
        WHEN COUNT(*) = 96096 THEN 'PASS: Exactly 96,096 unique customers'
        ELSE 'FAIL: Row count mismatch'
    END AS test_1_status
FROM dim_customer;

-- Test 2: Verify zero orphaned customer foreign keys in fact_sales
SELECT 
    COUNT(*) AS orphaned_sales_count,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS: 0 orphaned customer foreign keys'
        ELSE 'FAIL: Orphaned foreign keys detected'
    END AS test_2_status
FROM fact_sales f
LEFT JOIN dim_customer c 
    ON f.customer_unique_id = c.customer_unique_id
WHERE c.customer_unique_id IS NULL;

-- Test 3: Verify repeat customers can now be detected (expecting 2,801 delivered repeat buyers)
SELECT 
    COUNT(*) AS total_repeat_buyers_detected,
    CASE 
        WHEN COUNT(*) = 2801 THEN 'PASS: Exactly 2,801 delivered repeat buyers detected'
        ELSE 'FAIL: Repeat buyer count mismatch'
    END AS test_3_status
FROM (
    SELECT customer_unique_id
    FROM fact_sales
    GROUP BY customer_unique_id
    HAVING COUNT(DISTINCT order_id) > 1
) repeat_customers_subquery;
