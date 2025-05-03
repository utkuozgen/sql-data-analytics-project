/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CUSTOMER REPORT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Aim:
    - Report consolidates key customer metrics and behaviors

Includes:
    - Essential fields such as names, ages, and transaction details.
	- Customer category segments such as; (VIP, Regular, New) and age groups.
    - Customer-level metric aggregates: (total orders, total sales, total quantity purchased, total products, lifespan (in months)
    - Valuable KPIs: recency (months since last order), average order value, average monthly spend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

--------------------------------------------------------------------------------
-- Create: gold.report_customers --
--------------------------------------------------------------------------------
CREATE VIEW gold.report_customers as
WITH base_query as (
	SELECT
	s.order_number,
	s.product_key,
	s.order_date,
	s.sales_amount,
	s.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) as customer_name,
	DATEDIFF(year, c.birthdate, GETDATE()) as age
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_customers c
	ON c.customer_key = s.customer_key
	WHERE order_date IS NOT NULL)
, customer_aggregation as(
	SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) as total_orders,
	SUM(sales_amount) as total_sales,
	SUM(quantity) as total_quantity,
	COUNT(DISTINCT product_key) as total_products,
	MAX(order_date) as last_order,
	DATEDIFF (month, MIN(order_date), MAX(order_date)) as lifespan
	FROM base_query
	GROUP BY customer_key, customer_number, customer_name, age)
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE WHEN age < 18 THEN 'Under 18'
	 WHEN age BETWEEN 18 AND 25 THEN '18-25'
	 WHEN age BETWEEN 25 AND 40 THEN '25-40'
	 WHEN age BETWEEN 40 AND 65 THEN '40-65'
	 ELSE 'Over 65'
END age_group,
CASE WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	 WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	 ELSE 'New'
END customer_segment,
last_order,
DATEDIFF(month, last_order, GETDATE()) as recency,
total_orders,
total_sales,
total_quantity,
total_products,
lifespan,
CASE WHEN total_orders = 0 THEN 0
	 ELSE total_sales / total_orders 
END avg_order_value, -- Average order value
CASE WHEN lifespan = 0 THEN total_sales
	 ELSE total_sales / lifespan
END avg_monthly_spend -- Average monthly spend
FROM customer_aggregation


/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PRODUCT REPORT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Aim:
    - Report consolidates key product metrics and behaviors

Includes:
    - Essential fields such as product name, category, subcategory, and cost.
	- Product category segments by revenue such as; High-Performers, Mid-Range, or Low-Performers.
    - Product-level metric aggregates: (total orders, total sales, total quantity sold, total customers (unique), lifespan (in months)
    - Valuable KPIs: recency (months since last sale), average order revenue, average monthly revenue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/
--------------------------------------------------------------------------------
-- Create: gold.report_products --
--------------------------------------------------------------------------------
CREATE VIEW gold.report_products as
WITH base_query as(
	SELECT
	s.order_number,
	s.order_date,
	s.customer_key,
	s.sales_amount,
	s.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.product_cost
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	WHERE order_date IS NOT NULL
), product_aggregations as (
	SELECT
	product_key,
	product_name,
	category,
	subcategory,
	product_cost,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) as lifespan,
	MAX(order_date) as last_sale,
	COUNT(DISTINCT order_number) as total_orders,
	COUNT(DISTINCT customer_key) as total_customers,
	SUM(sales_amount) as total_sales,
	SUM(quantity) as total_quantity,
	ROUND(AVG(CAST(sales_amount as FLOAT) / NULLIF(quantity, 0)),1) as avg_selling_price
	FROM base_query
	GROUP BY product_key, product_name, category, subcategory, product_cost)
SELECT
product_key,
product_name,
category,
subcategory,
product_cost,
last_sale,
DATEDIFF(MONTH, last_sale, GETDATE()) as recency_in_mounts,
CASE
	WHEN total_sales > 50000 THEN 'High Performer'
	WHEN total_sales BETWEEN 10000 AND 50000 THEN 'Mid-Range'
	ELSE 'Low Performer'
END product_segment,
lifespan,
total_orders,
total_sales,
total_quantity,
total_customers,
avg_selling_price,
CASE
	WHEN total_orders = 0 THEN 0
	ELSE total_sales / total_orders
END avg_order_revenue,
CASE
	WHEN lifespan = 0 THEN total_sales
	ELSE total_sales / lifespan
END avg_monthly_revenue
FROM product_aggregations
