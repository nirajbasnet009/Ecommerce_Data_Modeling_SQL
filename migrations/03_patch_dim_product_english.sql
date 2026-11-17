-- ====================================================================
-- MIGRATION: 03_patch_dim_product_english.sql
-- PURPOSE: Add and populate product_category_name_english in dim_product 
--          with fallback mappings for unmapped and Unknown categories.
-- TARGET: ecommerce_db (MySQL 8.0)
-- AUTHOR: Niraj Basnet
-- ====================================================================

USE ecommerce_db;

-- --------------------------------------------------------------------
-- 1. Add product_category_name_english column to dim_product
-- Purpose: Provide an English category attribute directly inside dim_product 
--          so Power BI visuals display clean, readable English labels.
-- --------------------------------------------------------------------
ALTER TABLE dim_product
ADD COLUMN product_category_name_english VARCHAR(50) AFTER product_category_name;

-- --------------------------------------------------------------------
-- 2. Populate product_category_name_english using systematic fallback
-- Purpose: Map Portuguese categories to English from the translation table.
--          Maps 'Unknown' to 'Uncategorized', and uses COALESCE as a defensive
--          fallback so unmapped categories never produce NULLs in Power BI.
-- --------------------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

UPDATE dim_product p
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name
SET p.product_category_name_english = 
    CASE 
        WHEN p.product_category_name = 'Unknown' THEN 'Uncategorized'
        ELSE COALESCE(t.product_category_name_english, p.product_category_name)
    END;

SET SQL_SAFE_UPDATES = 1;

-- --------------------------------------------------------------------
-- 3. Enforce NOT NULL constraint on product_category_name_english
-- Purpose: Lock the English category attribute as mandatory so Power BI
--          never encounters missing categories or unexpected blanks.
-- --------------------------------------------------------------------
ALTER TABLE dim_product 
MODIFY COLUMN product_category_name_english VARCHAR(50) NOT NULL;

-- --------------------------------------------------------------------
-- 4. Post-Migration Verification & Assertions
-- Purpose: Programmatically prove that all products have an English category,
--          zero NULLs exist, and Top 10 category sales queries work cleanly.
-- --------------------------------------------------------------------

-- Test 1: Verify total products remains exactly 32,951
SELECT 
    COUNT(*) AS total_products,
    CASE 
        WHEN COUNT(*) = 32951 THEN 'PASS: Exactly 32,951 products accounted for'
        ELSE 'FAIL: Row count mismatch'
    END AS test_1_status
FROM dim_product;

-- Test 2: Verify zero NULL or empty English categories
SELECT 
    SUM(product_category_name_english IS NULL OR TRIM(product_category_name_english) = '') AS missing_english_categories,
    CASE 
        WHEN SUM(product_category_name_english IS NULL OR TRIM(product_category_name_english) = '') = 0 
        THEN 'PASS: 0 missing or empty English categories'
        ELSE 'FAIL: NULL or empty English categories found'
    END AS test_2_status
FROM dim_product;

-- Test 3: Top 10 Product Categories by Revenue (Clean English Output)
SELECT 
    p.product_category_name_english AS english_category,
    p.product_category_name AS portuguese_original,
    COUNT(f.order_item_id) AS items_sold,
    ROUND(SUM(f.price), 2) AS total_revenue_brl
FROM fact_sales f
INNER JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_category_name_english, p.product_category_name
ORDER BY total_revenue_brl DESC
LIMIT 10;
