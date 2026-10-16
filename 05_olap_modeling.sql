
-- ============================================================
-- PROJECT: Olist Brazilian E-commerce SQL Portfolio
-- PHASE 5: OLAP & DATA MODELING
-- FILE: 05_olap_modeling.sql
-- DATABASE: ecommerce_db
-- ============================================================
--
-- OBJECTIVE:
-- Design an analytics-friendly data model using SQL.
-- Build fact and dimension tables and perform OLAP analysis.
--
-- TOPICS:
-- 1. Fact table design
-- 2. Dimension tables
-- 3. Star schema
-- 4. Fact table grain
-- 5. Surrogate and business keys
-- 6. Analytical SQL queries
--
-- QUESTIONS: Q43 - Q50
-- STATUS: In Progress
--
-- ============================================================

USE ecommerce_db;

-- ============================================================
-- Q43: DESIGN A SALES FACT TABLE
-- ============================================================

CREATE TABLE fact_sales as
SELECT o.order_id as order_id,
       o.customer_id,
       o.order_purchase_timestamp as purchase_date,
       oi.order_item_id as order_item_id,
       oi.product_id,
       oi.seller_id,
       oi.price,
       oi.freight_value as freight_value
       
       FROM olist_orders_dataset o 
       INNER JOIN olist_order_items_dataset oi
       ON o.order_id = oi.order_id 
where o.order_status = 'delivered';

-- checking duplicate row from the fact_sales
select count(*) from fact_sales
group by order_id,order_item_id
having count(*) > 1;

-- checking null 
select COUNT(*) from fact_sales
where order_id IS NULL or order_item_id IS NULL;

-- data type conversion
ALTER TABLE fact_sales
MODIFY COLUMN order_id VARCHAR(32) NOT NULL;

SELECT
    MAX(CHAR_LENGTH(order_id)) AS max_order_id_length,
    MAX(CHAR_LENGTH(customer_id)) AS max_customer_id_length,
    MAX(CHAR_LENGTH(product_id)) AS max_product_id_length,
    MAX(CHAR_LENGTH(seller_id)) AS max_seller_id_length
FROM fact_sales;

SELECT DISTINCT
    purchase_date
FROM fact_sales
LIMIT 10;

SELECT
    COUNT(*) AS invalid_dates
FROM fact_sales
WHERE purchase_date IS NULL
   OR STR_TO_DATE(purchase_date, '%Y-%m-%d %H:%i:%s') IS NULL;
   
SELECT COUNT(*) FROM fact_sales
where price <> round(price,2) or freight_value <> round(freight_value,2);

select max(price), min(price), max(freight_value),min(freight_value) from fact_sales;

select COUNT(CASE WHEN price IS NULL THEN 1 END) from fact_sales;
select COUNT(CASE WHEN freight_value IS NULL THEN 1 END) from fact_sales;

ALTER TABLE fact_sales
    MODIFY COLUMN customer_id VARCHAR(32),
    MODIFY COLUMN product_id VARCHAR(32);
    
DESCRIBE fact_sales;

ALTER TABLE fact_sales
MODIFY COLUMN seller_id VARCHAR(32) not null;

ALTER TABLE fact_sales
MODIFY COLUMN purchase_date  DATETIME not null;

ALTER TABLE fact_sales
    MODIFY COLUMN price DECIMAL(12,2) NOT NULL,
    MODIFY COLUMN freight_value DECIMAL(12,2) NOT NULL;
    
DESCRIBE fact_sales;


alter table fact_sales
modify column customer_id varchar(32) not null,
modify column order_item_id int not null,
modify column product_id varchar(32) not null;

SELECT
    (SELECT SUM(price)
     FROM fact_sales) AS fact_total_sales,

    (SELECT ROUND(SUM(oi.price), 2)
     FROM olist_order_items_dataset AS oi
     INNER JOIN olist_orders_dataset AS o
         ON oi.order_id = o.order_id
     WHERE o.order_status = 'delivered') AS source_total_sales;
     
     SET SQL_SAFE_UPDATES = 0;
UPDATE fact_sales AS f
INNER JOIN olist_order_items_dataset AS oi
    ON f.order_id = oi.order_id
   AND f.order_item_id = oi.order_item_id
SET
    f.price = oi.price,
    f.freight_value = oi.freight_value;

SELECT
    SUM(price) AS total_sales
FROM fact_sales;
DROP TABLE IF EXISTS fact_sales;