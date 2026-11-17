-- ====================================================================
-- MIGRATION: 02_patch_dim_date_continuity.sql
-- PURPOSE: Generate a contiguous, gapless calendar table for dim_date 
--          covering all days from 2016 to 2018 for Power BI DAX support.
-- TARGET: ecommerce_db (MySQL 8.0)
-- AUTHOR: Niraj Basnet
-- ====================================================================

USE ecommerce_db;

-- --------------------------------------------------------------------
-- 1. Drop legacy foreign key constraint on fact_sales
-- Purpose: Safely unbind fact_sales from dim_date so MySQL allows us to
--          recreate dim_date without throwing a foreign key lock error (Error 3730).
-- --------------------------------------------------------------------
ALTER TABLE fact_sales 
DROP FOREIGN KEY fk_sales_date;

-- --------------------------------------------------------------------
-- 2. Drop and recreate dim_date table schema
-- Purpose: Design a rich, Kimball-standard date dimension structure 
--          with day names, month names, and sorting keys for Power BI.
-- Note: Named 'year_month_code' to avoid MySQL's reserved keyword YEAR_MONTH.
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    date_key INT NOT NULL PRIMARY KEY,
    full_date DATE NOT NULL,
    day_number TINYINT NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    month_number TINYINT NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    year_month_code VARCHAR(7) NOT NULL,
    quarter TINYINT NOT NULL,
    year SMALLINT NOT NULL,
    is_weekend TINYINT NOT NULL
);

-- --------------------------------------------------------------------
-- 3. Populate dim_date with all 1,096 continuous calendar days
-- Purpose: Generate every day from 2016-01-01 to 2018-12-31 with zero gaps.
-- Note: Setting cte_max_recursion_depth = 2000 allows loops past MySQL's 1000 limit.
-- --------------------------------------------------------------------
SET SESSION cte_max_recursion_depth = 2000;

INSERT INTO dim_date (
    date_key,
    full_date,
    day_number,
    day_name,
    month_number,
    month_name,
    year_month_code,
    quarter,
    year,
    is_weekend
)
WITH RECURSIVE date_range AS (
    SELECT DATE('2016-01-01') AS cal_date
    UNION ALL
    SELECT cal_date + INTERVAL 1 DAY 
    FROM date_range 
    WHERE cal_date < '2018-12-31'
)
SELECT 
    CAST(DATE_FORMAT(cal_date, '%Y%m%d') AS UNSIGNED) AS date_key,
    cal_date AS full_date,
    DAY(cal_date) AS day_number,
    DATE_FORMAT(cal_date, '%W') AS day_name,
    MONTH(cal_date) AS month_number,
    DATE_FORMAT(cal_date, '%M') AS month_name,
    DATE_FORMAT(cal_date, '%Y-%m') AS year_month_code,
    QUARTER(cal_date) AS quarter,
    YEAR(cal_date) AS year,
    CASE WHEN DAYOFWEEK(cal_date) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend
FROM date_range;

-- --------------------------------------------------------------------
-- 4. Re-establish foreign key constraint from fact_sales to dim_date
-- Purpose: Enforce referential integrity so every sale in fact_sales is
--          strictly bound to a valid calendar date in dim_date.
-- --------------------------------------------------------------------
ALTER TABLE fact_sales
ADD CONSTRAINT fk_sales_date
FOREIGN KEY (date_key)
REFERENCES dim_date(date_key);

-- --------------------------------------------------------------------
-- 5. Post-Migration Verification & Assertions
-- Purpose: Programmatically prove that dim_date has all 1,096 days,
--          zero orphaned foreign keys exist, and 100% of revenue reconciles.
-- --------------------------------------------------------------------

-- Test 1: Verify dim_date has all 1,096 continuous days
SELECT 
    COUNT(*) AS total_calendar_days,
    CASE 
        WHEN COUNT(*) = 1096 THEN 'PASS: All 1,096 continuous days present'
        ELSE 'FAIL: Date count mismatch'
    END AS test_1_status
FROM dim_date;

-- Test 2: Verify zero orphaned date foreign keys in fact_sales
SELECT 
    COUNT(*) AS orphaned_date_keys_count,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS: 0 orphaned date keys'
        ELSE 'FAIL: Orphaned date keys detected'
    END AS test_2_status
FROM fact_sales f
LEFT JOIN dim_date d 
    ON f.date_key = d.date_key
WHERE d.date_key IS NULL;

-- Test 3: Verify 100% financial and row reconciliation on inner join
SELECT 
    COUNT(*) AS joined_sales_records,
    ROUND(SUM(f.price), 2) AS joined_total_sales_brl,
    CASE 
        WHEN COUNT(*) = 110197 AND ROUND(SUM(f.price), 2) = 13221498.11 
        THEN 'PASS: Exactly 110,197 records and R$ 13,221,498.11 reconciled'
        ELSE 'FAIL: Revenue or row count mismatch'
    END AS test_3_status
FROM fact_sales f
INNER JOIN dim_date d 
    ON f.date_key = d.date_key;
