/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EXPLORATORY DATA ANALYSIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

-----------------------------------------------------------
-- DATABASE EXPLORATION --
-----------------------------------------------------------
-- Aim:
-- 	Explore the structure of the database, including the list of tables and their schemas.
--	Inspect the columns and metadata for specific tables.
-----------------------------------------------------------
--- Explore All Objects in the Database
SELECT* FROM INFORMATION_SCHEMA.TABLES

--- Explore All Columns in the Database
SELECT* FROM INFORMATION_SCHEMA.COLUMNS

--- Explore Columns in a Table
SELECT* FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers'

-----------------------------------------------------------
-- DIMENSION EXPLORATION --
-----------------------------------------------------------
-- Aim:
-- 	Explore the structure of dimension tables.
-----------------------------------------------------------
--- Explore All Countries That Customers are From
SELECT DISTINCT country FROM gold.dim_customers

--- Explore All Categories of Products
SELECT DISTINCT category FROM gold.dim_products

--- Explore All Categories and Subcategories of Products
SELECT DISTINCT category,subcategory FROM gold.dim_products
ORDER BY category, subcategory

--- Explore the Hierarchy of Products
SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY category, subcategory, product_name

-----------------------------------------------------------
-- DATE RANGE EXPLORATION --
-----------------------------------------------------------
-- Aim:
-- 	Determine the temporal boundaries of key data points.
--	Understand the range of historical data.
-----------------------------------------------------------
--- First Order, Last Order Dates and Order Range
SELECT 
MIN(order_date) as first_order_date, 
MAX(order_date) as last_order_date, 
DATEDIFF(year, MIN(order_date), MAX(order_date)) as order_range_in_years
FROM gold.fact_sales

--- Oldest and Youngest Customers
SELECT
MIN(birth_date) as oldest_birthdate,
DATEDIFF(year, MIN(birthdate), GETDATE()) As oldest_age,
MAX(birth_date) as youngest_birthdate,
DATEDIFF(year, MAX(birthdate), GETDATE()) As youngest_age
FROM gold.dim_customers

-----------------------------------------------------------
-- MEASURES EXPLORATION --
-----------------------------------------------------------
-- Aim:
-- 	Calculate aggregated metrics (e.g., totals, averages) for quick insights.
--	Identify overall trends or spot anomalies.
-----------------------------------------------------------
--- Total Sales
SELECT SUM(sales_amount) as total_sales FROM gold.fact_sales

--- Number of Items Sold
SELECT SUM(quantity) as total_quantity FROM gold.fact_sales

--- Average Selling Price
SELECT AVG(price) as avg_price FROM gold.fact_sales

--- Total Number of Orders
SELECT COUNT(DISTINCT order_number) as total_orders FROM gold.fact_sales

--- Total Number of Products
SELECT COUNT(DISTINCT product_name) as total_products FROM gold.dim_products

--- Total Number of Customers
SELECT COUNT(customer_key) as total_customers FROM gold.dim_customers

--- Total Number of Customers that Placed an Order
SELECT COUNT(DISTINCT customer_key) as total_customers FROM gold.fact_sales

--- All Key Metrics Together
SELECT 'Total Sales' as measure_name, SUM(sales_amount) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' as measure_name, SUM(quantity) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average Price' as measure_name, AVG(price) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total No. of Orders' as measure_name, COUNT(DISTINCT order_number) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total No. of Products' as measure_name, COUNT(DISTINCT product_name) as measure_value FROM gold.dim_products
UNION ALL
SELECT 'Total No. of Customers' as measure_name, COUNT(customer_key) as measure_value FROM gold.dim_customers

-----------------------------------------------------------
-- MAGNITUTE ANALYSIS --
-----------------------------------------------------------
-- Aim:
-- 	Quantify data and group results by specific dimensions.
--	Understanding data distribution across categories.
-----------------------------------------------------------
--- Total Customers by Countries
SELECT country, COUNT(customer_key) as total_customers 
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC

--- Total Customers by Gender
SELECT gender, COUNT(customer_key) as total_customers 
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC

--- Total Products by Category
SELECT category, COUNT(product_key) as total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC

--- Average Cost in Each Category
SELECT category, AVG(product_cost) as average_cost
FROM gold.dim_products
GROUP BY category
ORDER BY average_cost DESC

--- Total Revenue for Eacg Category
SELECT p.category, SUM(s.sales_amount) as total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON p.product_key = s.product_key
GROUP BY p.category
ORDER BY total_revenue DESC

--- Total Revenue Generated by Each Customer
SELECT c.customer_key, c.first_name, c.last_name, SUM(s.sales_amount) as total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
ON c.customer_key = s.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC

--- Distribution of Sales Across Countries
SELECT c.country, SUM(s.quantity) as total_sold_items
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
ON c.customer_key = s.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC

-----------------------------------------------------------
-- RANKING ANALYSIS --
-----------------------------------------------------------
-- Aim:
-- 	Rank items (e.g., products, customers) based on performance or other metrics.
--	Identify top performers or laggards.
-----------------------------------------------------------
--- 5 Products that Generate the Highest Revenue
SELECT TOP 5 
p.product_name, SUM(s.sales_amount) as total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC

--- Window Function Alternative
SELECT *
FROM(
	SELECT p.product_name, SUM(s.sales_amount) as total_revenue,
	ROW_NUMBER() OVER (ORDER BY SUM(s.sales_amount) DESC) as product_rank
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON p.product_key = s.product_key
	GROUP BY p.product_name)t
WHERE product_rank <= 5

--- 5 Products that Generate the Lowest Revenue
SELECT TOP 5 
p.product_name, SUM(s.sales_amount) as total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC

--- Top 10 Customers That Generated the Highest Revenue
SELECT TOP 10
c.customer_key, c.first_name, c.last_name, SUM(s.sales_amount) AS total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
ON c.customer_key = s.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC

--- 3 Customers That Placed the Lowest Orders
SELECT TOP 3
c.customer_key, c.first_name, c.last_name, COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
ON c.customer_key = s.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_orders 
