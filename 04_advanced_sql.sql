-- ============================================================
-- PROJECT: Olist Brazilian E-Commerce SQL Analysis
-- ============================================================
-- Author: Niraj Basnet
-- Database: ecommerce_db
-- DBMS: MySQL (Docker)
-- Dataset: Olist Brazilian E-Commerce Public Dataset
-- Source: Kaggle
-- File: 04_advanced_sql.sql
--
-- PURPOSE:
-- Analyze e-commerce performance using advanced SQL,
-- including Common Table Expressions (CTEs), window functions,
-- rankings, and multi-period trend calculations.
-- ============================================================

USE ecommerce_db;

-- ============================================================
-- SECTION 4: ADVANCED ANALYTICAL SQL (Q31 - Q42)
-- ============================================================

-- Q31: Rank product categories by delivered merchandise sales.
SELECT
    op.product_category_name,
    SUM(oi.price) AS total_sales,
    RANK() OVER (ORDER BY SUM(oi.price) DESC) AS sales_rank
FROM olist_orders_dataset o
INNER JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
INNER JOIN olist_products_dataset op
    ON oi.product_id = op.product_id
WHERE o.order_status = 'delivered'
GROUP BY 
    op.product_category_name
ORDER BY 
    sales_rank;


-- Q32: Compare ROW_NUMBER(), RANK(), and DENSE_RANK() for product category sales.
SELECT
    op.product_category_name,
    SUM(oi.price) AS total_sales,
    ROW_NUMBER() OVER (ORDER BY SUM(oi.price) DESC) AS row_num,
    RANK() OVER (ORDER BY SUM(oi.price) DESC) AS sales_rank,
    DENSE_RANK() OVER (ORDER BY SUM(oi.price) DESC) AS dense_rank_num
FROM olist_orders_dataset o
INNER JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
INNER JOIN olist_products_dataset op
    ON oi.product_id = op.product_id
WHERE o.order_status = 'delivered'
GROUP BY 
    op.product_category_name
ORDER BY 
    sales_rank, 
    op.product_category_name;


-- Q33: Find the top 3 sellers by delivered merchandise sales within each seller state.
WITH seller_state_sales AS (
    SELECT
        s.seller_state,
        s.seller_id,
        SUM(oi.price) AS total_sales
    FROM olist_orders_dataset o
    INNER JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    INNER JOIN olist_sellers_dataset s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
    GROUP BY 
        s.seller_id, 
        s.seller_state
),
ranked_state_sellers AS (
    SELECT
        seller_state,
        seller_id,
        total_sales,
        RANK() OVER (PARTITION BY seller_state ORDER BY total_sales DESC) AS state_rank
    FROM seller_state_sales
)
SELECT 
    seller_state,
    seller_id,
    total_sales,
    state_rank
FROM ranked_state_sellers 
WHERE state_rank <= 3
ORDER BY 
    seller_state, 
    state_rank;


-- Q34: Calculate monthly delivered merchandise sales and the running total of sales over time.
WITH monthly_sales_summary AS (
    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS sales_month,
        SUM(oi.price) AS monthly_sales
    FROM olist_orders_dataset o 
    INNER JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 
        sales_month
),
cumulative_sales_summary AS (
    SELECT
        sales_month,
        monthly_sales,
        SUM(monthly_sales) OVER (
            ORDER BY sales_month 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_sales
    FROM monthly_sales_summary
)
SELECT 
    sales_month,
    monthly_sales,
    cumulative_sales
FROM cumulative_sales_summary
ORDER BY 
    sales_month;


-- Q35: Calculate the percentage increase or decrease in delivered merchandise sales compared with the previous month.
WITH monthly_sales_summary AS (
    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS sales_month,
        SUM(oi.price) AS monthly_sales
    FROM olist_orders_dataset o 
    INNER JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 
        sales_month
),
monthly_sales_comparison AS (
    SELECT
        sales_month,
        monthly_sales,
        LAG(monthly_sales) OVER (ORDER BY sales_month) AS previous_month_sales
    FROM monthly_sales_summary
)
SELECT 
    sales_month,
    monthly_sales,
    previous_month_sales,
    ROUND(
        ((monthly_sales - previous_month_sales) * 100.0) / NULLIF(previous_month_sales, 0),
        2
    ) AS growth_percentage
FROM monthly_sales_comparison
ORDER BY 
    sales_month;


-- Q36: Calculate a three-month moving average of delivered merchandise sales.
WITH monthly_sales_summary AS (
    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS sales_month,
        SUM(oi.price) AS monthly_sales
    FROM olist_orders_dataset o 
    INNER JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 
        sales_month
),
moving_average_summary AS (
    SELECT
        sales_month,
        monthly_sales,
        ROUND(
            AVG(monthly_sales) OVER (
                ORDER BY sales_month 
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS three_month_moving_avg
    FROM monthly_sales_summary
)
SELECT 
    sales_month,
    monthly_sales,
    three_month_moving_avg
FROM moving_average_summary
ORDER BY 
    sales_month;


-- Q37: Calculate each product category's percentage contribution to total delivered merchandise sales.
WITH category_sales_summary AS (
    SELECT
        p.product_category_name,
        SUM(oi.price) AS total_sales_by_category
    FROM olist_orders_dataset o
    INNER JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    INNER JOIN olist_products_dataset p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY 
        p.product_category_name
),
overall_sales_summary AS (
    SELECT
        product_category_name,
        total_sales_by_category,
        ROUND(
            SUM(total_sales_by_category) OVER (
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ),
            2
        ) AS total_market_sales
    FROM category_sales_summary
)
SELECT 
    product_category_name,
    total_sales_by_category,
    ROUND(
        (total_sales_by_category * 100.0 / NULLIF(total_market_sales, 0)),
        2
    ) AS sales_percentage
FROM overall_sales_summary
ORDER BY 
    total_sales_by_category DESC;


-- Q38: Find the top 3 product categories by delivered merchandise sales within each customer state.
WITH category_sales_by_state AS (
    SELECT 
        c.customer_state,
        p.product_category_name,
        SUM(oi.price) AS category_sales
    FROM olist_orders_dataset o
    INNER JOIN olist_customers_dataset c
        ON o.customer_id = c.customer_id
    INNER JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    INNER JOIN olist_products_dataset p
        ON oi.product_id = p.product_id 
    WHERE o.order_status = 'delivered'
    GROUP BY 
        c.customer_state,
        p.product_category_name
),
ranked_categories_by_state AS (
    SELECT 
        customer_state,
        product_category_name,
        category_sales,
        RANK() OVER (
            PARTITION BY customer_state 
            ORDER BY category_sales DESC
        ) AS category_rank
    FROM category_sales_by_state
)
SELECT 
    customer_state,
    product_category_name,
    category_sales,
    category_rank
FROM ranked_categories_by_state 
WHERE category_rank <= 3
ORDER BY 
    customer_state, 
    category_rank;


-- Q39: Identify customers who placed more than one order and rank them by their number of orders.
WITH repeat_order_counts AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM olist_customers_dataset c
    INNER JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
    GROUP BY 
        c.customer_unique_id
    HAVING 
        total_orders > 1
),
ranked_repeat_customers AS (
    SELECT
        customer_unique_id,
        total_orders,
        RANK() OVER (ORDER BY total_orders DESC) AS customer_rank
    FROM repeat_order_counts
)
SELECT 
    customer_unique_id,
    total_orders,
    customer_rank
FROM ranked_repeat_customers 
ORDER BY 
    customer_rank, 
    total_orders DESC;


-- Q40: Calculate the number of days between consecutive orders placed by repeat customers.
WITH customer_order_history AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp AS purchase_date,
        COUNT(*) OVER (PARTITION BY c.customer_unique_id) AS total_customer_orders
    FROM olist_customers_dataset c
    INNER JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
),
repeat_order_intervals AS (
    SELECT 
        customer_unique_id, 
        order_id,
        purchase_date,
        LAG(purchase_date) OVER (
            PARTITION BY customer_unique_id 
            ORDER BY purchase_date, order_id
        ) AS previous_purchase_date
    FROM customer_order_history
    WHERE total_customer_orders >= 2
)
SELECT 
    customer_unique_id,
    order_id,
    purchase_date,
    previous_purchase_date,
    TIMESTAMPDIFF(DAY, previous_purchase_date, purchase_date) AS days_since_previous_order
FROM repeat_order_intervals
ORDER BY 
    customer_unique_id, 
    purchase_date;


-- Q41: Calculate the average number of days between consecutive purchases for each repeat customer.
WITH customer_order_history AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp AS purchase_date,
        COUNT(*) OVER (PARTITION BY c.customer_unique_id) AS total_customer_orders
    FROM olist_customers_dataset c
    INNER JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
),
repeat_order_intervals AS (
    SELECT 
        customer_unique_id, 
        total_customer_orders,
        purchase_date,
        LAG(purchase_date) OVER (
            PARTITION BY customer_unique_id 
            ORDER BY purchase_date, order_id
        ) AS previous_purchase_date
    FROM customer_order_history
    WHERE total_customer_orders >= 2
),
order_day_intervals AS (
    SELECT 
        customer_unique_id,
        total_customer_orders,
        TIMESTAMPDIFF(DAY, previous_purchase_date, purchase_date) AS days_since_previous_order
    FROM repeat_order_intervals
)
SELECT 
    customer_unique_id,
    total_customer_orders,
    ROUND(AVG(days_since_previous_order), 2) AS avg_days_between_orders
FROM order_day_intervals
GROUP BY 
    customer_unique_id, 
    total_customer_orders
ORDER BY 
    total_customer_orders DESC, 
    avg_days_between_orders ASC;


-- Q42: What percentage of each state's total merchandise sales is contributed by each seller?
WITH seller_state_sales AS (
    SELECT 
        s.seller_id,
        s.seller_state,
        SUM(oi.price) AS seller_total_sales
    FROM olist_orders_dataset o
    INNER JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    INNER JOIN olist_sellers_dataset s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
    GROUP BY 
        s.seller_state, 
        s.seller_id
),
state_sales_totals AS (
    SELECT 
        seller_id,
        seller_state,
        seller_total_sales,
        SUM(seller_total_sales) OVER (PARTITION BY seller_state) AS state_total_sales
    FROM seller_state_sales
)
SELECT 
    seller_state, 
    seller_id, 
    seller_total_sales, 
    state_total_sales,
    ROUND((seller_total_sales * 100.0) / NULLIF(state_total_sales, 0), 2) AS contribution_percentage
FROM state_sales_totals
ORDER BY 
    seller_state, 
    contribution_percentage DESC;
