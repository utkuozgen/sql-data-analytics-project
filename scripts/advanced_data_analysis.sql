/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ADVANCED DATA ANALYSIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/
-----------------------------------------------------------
-- CHANGE OVER TIME ANALYSIS --
-----------------------------------------------------------
-- Aim:
--    To track trends, growth, and changes in key metrics over time.
--    For time-series analysis and identifying seasonality.
--    To measure growth or decline over specific periods.
-----------------------------------------------------------
--- Total Sales, Customers and Number of Items per Year
SELECT 
YEAR(order_date) as order_year, 
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

--- Total Sales, Customers and Number of Items per Month
SELECT 
YEAR(order_date) as order_year,
MONTH(order_date) as order_month,
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date)
-- Alternative
SELECT 
DATETRUNC(month, order_date) as order_date,
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month, order_date)

-----------------------------------------------------------
-- CUMULATIVE ANALYSIS --
-----------------------------------------------------------
-- Aim:
--    To calculate running totals or moving averages for key metrics.
--    To track performance over time cumulatively.
--    Useful for growth analysis or identifying long-term trends.
-----------------------------------------------------------
SELECT
order_date,
total_sales,
SUM(total_sales) OVER (ORDER BY order_date) as running_total_sales
FROM
(
	SELECT
	DATETRUNC(month, order_date) as order_date,
	SUM(sales_amount) as total_sales
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(month, order_date)
)t

--- Total Sales per Month and Running Total of the Sales per Year
SELECT
order_date,
total_sales,
SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) as running_total_sales
FROM
(
	SELECT
	DATETRUNC(month, order_date) as order_date,
	SUM(sales_amount) as total_sales
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(month, order_date)
)t

--- Moving Average Price
SELECT
order_date,
total_sales,
SUM(total_sales) OVER (ORDER BY order_date) as running_total_sales,
AVG(average_price) OVER (ORDER BY order_date) as moving_average_price
FROM
(
	SELECT
	DATETRUNC(month, order_date) as order_date,
	SUM(sales_amount) as total_sales,
	AVG(price) as average_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(month, order_date)
)t

-----------------------------------------------------------
-- PERFORMANCE ANALYSIS --
-----------------------------------------------------------
-- Aim:
--    Measure the performance of products, customers, or regions over time.
--    Benchmarking and identifying high-performing entities.
--    Track yearly trends and growth..
-----------------------------------------------------------
--- Comparison of Products' Yearly Performance VS. Average Performance and Year-Over-Year Analysis
WITH yearly_product_sales as (
	SELECT 
	YEAR(s.order_date) as order_year,
	p.product_name,
	SUM(s.sales_amount) as current_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(s.order_date), p.product_name)
SELECT
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) as average_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) as diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Average'
	 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Average'
	 ELSE 'Average'
END average_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as previous_year_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as previous_year_difference,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	 ELSE 'No Change'
END previous_year_change
FROM yearly_product_sales
ORDER BY product_name, order_year

-----------------------------------------------------------
-- PART-TO-WHOLE ANALYSIS --
-----------------------------------------------------------
-- Aim:
--    Compare performance or metrics across dimensions or time periods.
--    Evaluate differences between categories.
--    Useful for A/B testing or regional comparisons.
-----------------------------------------------------------
--- Percentage of Sales per Category 
WITH category_sales as(
	SELECT category, 
	SUM(sales_amount) as total_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON p.product_key = s.product_key
	GROUP BY category)
SELECT 
category,
total_sales,
SUM(total_sales) OVER () as overall_sales,
CONCAT(ROUND((CAST(total_sales as FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') as percentage_of_total
FROM category_sales
ORDER BY total_sales DESC

-----------------------------------------------------------
-- DATA SEGMENTATION --
-----------------------------------------------------------
-- Aim:
--    Group data into meaningful categories for targeted insights.
--    Customer segmentation, product categorization, or regional analysis.
-----------------------------------------------------------
--- Products Segmented into Cost Ranges and Number of Products per Range
WITH product_segments as(
	SELECT
	product_key,
	product_name,
	product_cost,
	CASE WHEN product_cost < 100 THEN 'Below 100'
		 WHEN product_cost BETWEEN 100 AND 500 THEN '100-500'
		 WHEN product_cost BETWEEN 500 AND 1000 THEN '500-1000'
		 WHEN product_cost BETWEEN 1000 AND 1500 THEN '1000-1500'
		 WHEN product_cost BETWEEN 1500 AND 2000 THEN '1500-2000'
		 ELSE 'Above 2000'
	END cost_range
	FROM gold.dim_products)
SELECT
cost_range,
COUNT(product_key) as total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC

--- Customers Grouped Based on Their Spending Behaviour
WITH customer_segments as(
	SELECT DISTINCT
	c.customer_key,
	MIN(order_date) as first_order,
	MAX(order_date) as last_order,
	DATEDIFF (month, MIN(order_date), MAX(order_date)) as lifespan,
	SUM(sales_amount) as total_sales
	FROM gold.dim_customers c
	LEFT JOIN gold.fact_sales s
	ON c.customer_key = s.customer_key
	GROUP BY c.customer_key)
SELECT
customer_key,
total_sales,
lifespan,
CASE WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	 WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	 ELSE 'New'
END customer_segment
FROM customer_segments
ORDER BY customer_key

--- Number of Customers per Segment
WITH customer_segments as(
	SELECT DISTINCT
	c.customer_key,
	MIN(order_date) as first_order,
	MAX(order_date) as last_order,
	DATEDIFF (month, MIN(order_date), MAX(order_date)) as lifespan,
	SUM(sales_amount) as total_sales
	FROM gold.dim_customers c
	LEFT JOIN gold.fact_sales s
	ON c.customer_key = s.customer_key
	GROUP BY c.customer_key)
SELECT
customer_segment,
COUNT(customer_key) as total_customers
FROM(
	SELECT customer_key,
	CASE WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
		 WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		 ELSE 'New'
	END customer_segment
	FROM customer_segments) t
GROUP BY customer_segment
ORDER BY total_customers DESC
