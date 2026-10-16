
-- ============================================================
-- PROJECT: Olist E-Commerce Sales Analytics & Data Modeling
-- AUTHOR: Niraj Basnet
-- DATABASE: ecommerce_db
-- FILE: 04_advanced_sql.sql
-- ============================================================
-- PURPOSE:
-- Analyze e-commerce performance using advanced SQL,
-- including CTEs, window functions, rankings, and trends.
--
-- SECTION 4: ADVANCED SQL (Q31-Q42)
-- ============================================================

USE ecommerce_db;

-- Q31: Rank product categories by delivered merchandise sales.

SELECT
     op.product_category_name,
     SUM(oi.price) AS total_sale,
     RANK() OVER(ORDER BY SUM(oi.price) DESC) as sales_rank

FROM olist_orders_dataset o
INNER JOIN olist_order_items_dataset oi
ON o.order_id = oi.order_id
INNER JOIN olist_products_dataset op
ON oi.product_id = op.product_id

WHERE 
	 o.order_status = 'delivered'

GROUP BY 
        op.product_category_name
ORDER BY 
		sales_rank;
        
        
-- Compare ROW_NUMBER(), RANK(), and DENSE_RANK() for product category sales.
	SELECT
		 op.product_category_name,
		 SUM(oi.price) AS total_sale,
		 ROW_NUMBER() OVER(ORDER BY SUM(oi.price) DESC) as row_num,
		 RANK() OVER(ORDER BY SUM(oi.price) DESC) as sales_rank,
		 DENSE_RANK() OVER(ORDER BY SUM(oi.price) DESC) as 'dense_rank'


	FROM olist_orders_dataset o
	INNER JOIN olist_order_items_dataset oi
	ON o.order_id = oi.order_id
	INNER JOIN olist_products_dataset op
	ON oi.product_id = op.product_id

	WHERE 
		 o.order_status = 'delivered'

	GROUP BY 
			op.product_category_name
	ORDER BY 
			sales_rank, op.product_category_name;
            
            
-- Find the top 3 sellers by delivered merchandise sales within each seller state.
WITH cte_table AS (
	SELECT
		  s.seller_state,
		  s.seller_id,
		  SUM(oi.price) as total_sales
	FROM
		olist_orders_dataset o
	INNER JOIN olist_order_items_dataset oi
	ON 
	   o.order_id = oi.order_id
	INNER JOIN olist_sellers_dataset s
	ON 
	  oi.seller_id = s.seller_id

	WHERE 
		 o.order_status = 'delivered'
	GROUP BY 
		  s.seller_id,s.seller_state),

	cte_table2 AS (
	SELECT *,
	RANK() 
		  OVER(PARTITION BY seller_state ORDER BY total_sales DESC) AS state_rank

	FROM cte_table)

SELECT * FROM cte_table2 WHERE state_rank <= 3
ORDER BY state_rank;


-- Calculate monthly delivered merchandise sales and the running total of sales over time.
WITH monthly_sales_table AS (
SELECT
      DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS sales_month,
	  SUM(oi.price) AS monthly_sales
      FROM olist_orders_dataset o 
      INNER JOIN olist_order_items_dataset oi
      ON o.order_id = oi.order_id
	  WHERE
           o.order_status = 'delivered'
      GROUP BY sales_month order by sales_month
      ),
cumulative_sales_table AS (
	  SELECT *,
           SUM(monthly_sales) OVER(ORDER BY sales_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
	  FROM monthly_sales_table
      )
SELECT * FROM cumulative_sales_table
ORDER BY sales_month;


--  Calculate the percentage increase or decrease in delivered merchandise sales compared with the previous month.

WITH monthly_sales_table AS (
SELECT
      DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS sales_month,
	  SUM(oi.price) AS monthly_sales
      FROM olist_orders_dataset o 
      INNER JOIN olist_order_items_dataset oi
      ON o.order_id = oi.order_id
	  WHERE
           o.order_status = 'delivered'
      GROUP BY sales_month order by sales_month
      ),
cumulative_sales_table AS (
	  SELECT *,
           LAG(monthly_sales) OVER(ORDER BY sales_month) AS previous_month_sales
	  FROM monthly_sales_table
      )
SELECT *,
	   ROUND(((monthly_sales - previous_month_sales) * 100)/NULLIF(previous_month_sales,0),2) AS growth_percentage
FROM cumulative_sales_table
ORDER BY sales_month;


-- Calculate a three-month moving average of delivered merchandise sales.
WITH monthly_sales_table AS (
SELECT
      DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS sales_month,
	  SUM(oi.price) AS monthly_sales
      FROM olist_orders_dataset o 
      INNER JOIN olist_order_items_dataset oi
      ON o.order_id = oi.order_id
	  WHERE
           o.order_status = 'delivered'
      GROUP BY sales_month order by sales_month
      ),
cumulative_sales_table AS (
	  SELECT *,
           AVG(monthly_sales) OVER(ORDER BY sales_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_average
	  FROM monthly_sales_table
      )
SELECT * FROM cumulative_sales_table
ORDER BY sales_month;


-- Calculate each product category's percentage contribution to total delivered merchandise sales.

WITH total_categorywise_sales_table AS (
	SELECT
		 p.product_category_name as product_category_name,
		 SUM(oi.price) as total_sales_by_category
	FROM olist_orders_dataset o
	INNER JOIN olist_order_items_dataset oi
		 ON o.order_id = oi.order_id
	INNER JOIN olist_products_dataset p
		 ON oi.product_id = p.product_id
	WHERE o.order_status = 'delivered'
	GROUP BY 
		  p.product_category_name
	ORDER BY
		  total_sales_by_category DESC
),
category_total_sales AS (
SELECT *,
       ROUND(SUM(total_sales_by_category) OVER(ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),2) AS total_sales
       FROM total_categorywise_sales_table
	 )
SELECT product_category_name,
       total_sales_by_category,
       ROUND((total_sales_by_category * 100 /NULLIF(total_sales,0)),2) AS sales_percentage
       FROM category_total_sales;


-- Find the top 3 product categories by delivered merchandise sales within each customer state.
with cte_table as (
SELECT 
	  c.customer_state as customer_state,
      p.product_category_name as product_category_name,
      SUM(oi.price) as category_sales
      
      FROM olist_orders_dataset o
      INNER JOIN olist_customers_dataset c
      ON o.customer_id = c.customer_id
      INNER JOIN olist_order_items_dataset oi
      ON o.order_id = oi.order_id
      INNER JOIN olist_products_dataset p
      ON oi.product_id = p.product_id 

WHERE o.order_status = 'delivered'
GROUP BY customer_state,product_category_name)
,

cte_table2 as (
select *,
            RANK() OVER(PARTITION BY customer_state ORDER BY category_sales DESC) as ran
from cte_table 
)
select * from cte_table2 where ran <= 3;


-- Identify customers who placed more than one order and rank them by their number of orders.

with cte_table_1 as (
SELECT
	 c.customer_unique_id as customer_unique_id,
     count(o.order_id) as total_orders
     FROM olist_customers_dataset c
     INNER JOIN olist_orders_dataset o
     ON c.customer_id = o.customer_id
     
GROUP BY customer_unique_id
HAVING total_orders > 1
),
cte_table_2 as (
     SELECT
          *,
          RANK() over(order by total_orders desc) as customer_rank
          FROM
            cte_table_1)
select * from cte_table_2 order by customer_rank;


-- Calculate the number of days between consecutive orders placed by repeat customers.
with cte_table as(
SELECT 
       customer_unique_id AS customer_unique_id,
       order_purchase_timestamp as buying_date,
       order_id as order_id,
       count(*) over(partition by customer_unique_id) as order_count

       FROM olist_customers_dataset c
       INNER JOIN olist_orders_dataset o
       ON c.customer_id = o.customer_id

),
cte_table_1 as (
select customer_unique_id, 
       order_id,
	   buying_date,

       lag(buying_date) over(partition by customer_unique_id order by buying_date,order_id) as previous_purchase_date
from cte_table
where order_count >= 2)
SELECT *,
		timestampdiff(DAY, previous_purchase_date, buying_date) as days_since_previous_order

FROM
    cte_table_1;
       
     
     
-- Calculate the average number of days between consecutive purchases for each repeat customer.


with cte_table_1 as(
SELECT 
       customer_unique_id AS customer_unique_id,
       order_purchase_timestamp as buying_date,
       order_id as order_id,
       count(*) over(partition by customer_unique_id) as order_count

       FROM olist_customers_dataset c
       INNER JOIN olist_orders_dataset o
       ON c.customer_id = o.customer_id

),
cte_table_2 as (
select customer_unique_id, 
       order_count,
	   buying_date,

       LAG(buying_date) OVER(partition by customer_unique_id order by buying_date,order_id) as previous_purchase_date
from cte_table_1
where 
    order_count >= 2

),

cte_table_3 as (
SELECT customer_unique_id,
        order_count,
		timestampdiff(DAY, previous_purchase_date, buying_date) as days_since_previous_order

FROM
    cte_table_2
)
 select 
        customer_unique_id,
        order_count,
		ROUND(AVG(days_since_previous_order),2) as avg_days_between_orders
from cte_table_3
group by customer_unique_id,order_count
order by order_count DESC
;


-- What percentage of each state's total merchandise sales is contributed by each seller?


with seller_sales as (
SELECT 
       s.seller_id,
	   s.seller_state as seller_state,
       sum(oi.price) as sellers_total_sales
       FROM olist_orders_dataset o
       INNER JOIN olist_order_items_dataset oi
       ON o.order_id = oi.order_id
       INNER JOIN olist_sellers_dataset s
       ON oi.seller_id = s.seller_id

WHERE o.order_status = 'delivered'
group by seller_state, seller_id
),
states_sales as (
SELECT 
       seller_id,
       seller_state,
       sellers_total_sales,
       sum(sellers_total_sales) OVER(partition by seller_state) as state_total_sales

FROM seller_sales
)
select seller_state, seller_id, sellers_total_sales, state_total_sales,
	   ROUND((sellers_total_sales * 100)/NULLIF(state_total_sales,0),2) as contribution_pct
from states_sales
order by seller_state
;


