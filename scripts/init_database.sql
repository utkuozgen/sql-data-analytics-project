/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Create Database and Schemas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Script Aim:
    Script creates a new database named "datawarehouseanalytics" after checking if it exists and creates schema called "gold". 
    If database exists it is dropoed and recreated. 

Warning
    Script will delete all data that exists in the database if "datawarehouseanalytics" exists, use with caution
*/

USE master;
GO

-- Drop and recreate the "datawarehouseanalytics" database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'datawarehouseanalytics')
BEGIN
    ALTER DATABASE datawarehouseanalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE datawarehouseanalytics;
END;
GO

-- Create the "datawarehouseanalytics" database
CREATE DATABASE datawarehouseanalytics;
GO

USE datawarehouseanalytics;
GO

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int,
	product_id int,
	product_number nvarchar(50),
	product_name nvarchar(50),
	category_id nvarchar(50),
	category nvarchar(50),
	subcategory nvarchar(50),
	maintenance nvarchar(50),
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'D:\sql\sql-data-analytics-project\datasets\gold.dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'D:\sql\sql-data-analytics-project\datasets\gold.dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'D:\sql\sql-data-analytics-project\datasets\gold.fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO
