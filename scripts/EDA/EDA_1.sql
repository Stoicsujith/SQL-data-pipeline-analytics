/*
===============================================================================
EDA Part 1 - SQL Script
===============================================================================
Purpose:
    Conducts initial exploratory data analysis (EDA) on the Gold Layer dataset
    created during the Data Warehouse project. This is the first round of EDA 
    focused on structural, categorical, temporal, and basic business insights.

Coverage:
    - Schema Discovery:
        > Lists available tables and columns using INFORMATION_SCHEMA.
        > Notes that misspelled names in INFORMATION_SCHEMA return empty results 
          (not errors).
    
    - Dimension Understanding:
        > Uses DISTINCT to explore unique values across customer and product fields.
        > Profiles country, gender, marital status, and product category/sub-category.

    - Date Analysis:
        > Extracts min/max order dates and computes shipping/delivery durations.
        > Identifies youngest and oldest customers based on birthdate.

    - Measure Summary:
        > Calculates total sales, quantity sold, order count, average price.
        > Differentiates between total customers and those who placed orders.

    - Magnitude & Ranking:
        > Aggregates customers by country and gender, products by category.
        > Computes revenue per customer and category.
        > Ranks top and bottom performing products and customers by sales/orders.

Usage:
    Use this script as the foundation for understanding the scope, patterns, and
    basic KPIs in the dataset. 
===============================================================================
*/


USE datawarehouse;
GO

--=======================
-- DATABASE EXPLORATION 
--=======================
SELECT * FROM INFORMATION_SCHEMA.TABLES

-- COLUMN OVERVIEW
-- while inputing table_schema or table_name 
-- validate spelling and name as this query doesn't throws an error

SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'GOLD'
	AND TABLE_NAME = 'DIM_PRODUCT';

--=========================
--	DIMENSION EXPLORATION 
--=========================
/*
--------------------------------
 Dimension vs facts/ measures
---------------------------------
-> if the data is descriptive then dimension
-> if the data is qunatitative but doesn't makes sense while aggregating means dimension (cust_id)
-> Dimension answers who?, why?, which one? etc..

-> if the data is quantitative and makes sense while aggregating then fact/measures
-> fact/ measure answers how much?, how many? etc..
*/

-- Dimension Exploration in customers

-- DIMENSION BY COUNTRY
SELECT DISTINCT COUNTRY
FROM gold.dim_customers

-- DIMENSION BY GENDER
SELECT DISTINCT GENDER
FROM gold.dim_customers

-- DIMENSION BY MARITAL_STATUS
SELECT DISTINCT MARITAL_STATUS
FROM gold.dim_customers

-- DIMENSION EXPLORATION IN PRODUCTS

-- DIMENSION BY CATEGORY
SELECT DISTINCT category, sub_category, product_name
FROM gold.dim_product;

--===================
-- DATE EXPLORATION
--===================
-- date of first_order and last_order 
-- how many years of sales are available in the data
SELECT MIN(ORDER_DATE) AS first_order_date, 
	   MAX(ORDER_DATE) AS last_order_date,
	   DATEDIFF(YEAR, MIN(ORDER_DATE), MAX(ORDER_DATE)) AS order_range_years
FROM GOLD.fact_sales;

-- average time to ship the product from order date
-- average time taken to deliver the product from order date
SELECT AVG(DATEDIFF(DAY, order_date, ship_date)) AS avg_shipping_time_days,
	   AVG(DATEDIFF(DAY, order_date, due_date))  AS avg_delivery_time_days
FROM GOLD.fact_sales;

-- finding the youngest and oldest customer

SELECT TOP 1
	'OLDEST_CUSTOMERS' AS Ranking,
	first_name + ' ' + last_name AS Customer_name,
	DATEDIFF(YEAR, birthdate, GETDATE()) AS AGE
FROM gold.dim_customers
WHERE birthdate = (SELECT MIN(birthdate) FROM gold.dim_customers)

UNION ALL

SELECT TOP 1
	'YOUNGEST_CUSTOMERS' AS Ranking,
	first_name + ' ' + last_name AS Customer_name,
	DATEDIFF(YEAR, birthdate, GETDATE()) AS AGE
FROM gold.dim_customers
WHERE birthdate = (SELECT MAX(birthdate) FROM gold.dim_customers);

--======================
-- MEASURE ANALYSIS
--======================

-- Find the total sales
-- Find how many items are sold
-- Find the average selling price
-- Find the total number of orders
-- Find the total number of products
-- Find the total number of customers
-- Find the total number of customers that has placed an order 


SELECT 'Total_Sales' as Measure_name, SUM(SALES_AMOUNT) AS Measure_value from gold.fact_sales
UNION ALL
SELECT 'Total_Quantity' as Measure_name, SUM(QUANTITY) AS Measure_value from gold.fact_sales
UNION ALL
SELECT 'Average_Price' as Measure_name, AVG(PRICE) AS Measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total_no_of_Orders' as Measure_name, COUNT(ORDER_NUMBER) AS Measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total_no_of_Products' as Measure_name, COUNT(DISTINCT PRODUCT_KEY) AS Measure_value FROM gold.dim_product
UNION ALL
SELECT 'Total_no_of_Customers' as Measure_name, COUNT(DISTINCT customer_id) AS Measure_value FROM gold.dim_customers
UNION ALL
SELECT 'Customers_Placed_orders' as Measure_name, COUNT(DISTINCT CUSTOMER_KEY) AS Measure_value FROM gold.fact_sales;


--=======================
-- MAGNITUDE ANALYSIS
--=======================

-- Find total customers by country
SELECT 
	country,
	COUNT(customer_id) AS Total_Customers
FROM gold.dim_customers
GROUP BY COUNTRY
ORDER BY COUNT(customer_id) DESC;

-- Find total customers by gender
SELECT
	GENDER,
	COUNT(CUSTOMER_ID) AS Total_Customers
FROM gold.dim_customers
GROUP BY GENDER
ORDER BY COUNT(customer_id) DESC;

-- Find total products by category
SELECT 
	CATEGORY,
	COUNT(product_id) AS Total_Products
FROM gold.dim_product
GROUP BY category
ORDER BY COUNT(product_id) DESC;

-- What is the average cost in each category
SELECT 
	CATEGORY,
	'$ ' + CAST(AVG(COST)AS NVARCHAR(20)) AS AVG_COST
FROM gold.dim_product
GROUP BY category
ORDER BY AVG(COST) DESC;

-- What is the average sales for each country
SELECT 
	COUNTRY,
	'$ ' + CAST(AVG(sales) AS NVARCHAR(20)) AS AVG_Sales
FROM (
SELECT 
	C.COUNTRY AS COUNTRY,
	S.CUSTOMER_KEY,
	SUM(sales_amount) AS sales
FROM gold.fact_sales S
LEFT JOIN gold.dim_customers C
ON		S.customer_key = C.customer_key
GROUP BY C.country, S.customer_key) T
GROUP BY COUNTRY
ORDER BY AVG(sales) DESC;

-- What is the total revenue generated for each category
SELECT 
	P.category,
	'$ ' + CAST(SUM(S.sales_amount) AS NVARCHAR(20)) AS Total_revenue
FROM gold.fact_sales S
LEFT JOIN gold.dim_product P
ON	S.product_key = P.product_key
GROUP BY P.category
ORDER BY SUM(S.SALES_AMOUNT) DESC;

-- Find total revenue generated by each customer
SELECT 
    C.customer_id,
    C.FIRST_NAME + ' ' + C.LAST_NAME AS Customer_name,
    SUM(S.sales_amount) AS total_sales
FROM gold.fact_sales S
LEFT JOIN gold.dim_customers C
    ON S.customer_key = C.customer_key
GROUP BY C.customer_id, C.FIRST_NAME, C.LAST_NAME
ORDER BY total_sales DESC;

-- what is the distribution of sold items across countries
SELECT 
	C.COUNTRY,
	SUM(S.QUANTITY) AS TOTAL_SOLD
FROM gold.fact_sales S
LEFT JOIN gold.dim_customers C
ON		S.customer_key = C.customer_key
GROUP BY C.country
ORDER BY SUM(S.quantity) DESC;




--===================
-- RANKING ANALYSIS
--===================

-- WHICH 5 PRODUCT GENERATE HIGHEST SALES
SELECT TOP 5
	P.product_name AS Product_Name,
	SUM(S.sales_amount) AS TOTAL_SALES
FROM gold.fact_sales S
LEFT JOIN gold.dim_product P
ON S.product_key = P.product_key
GROUP BY P.product_name
ORDER BY SUM(S.sales_amount) DESC;

-- WORST 5 PERFORMING PRODUCT IN SALES
SELECT TOP 5
	P.product_name AS Product_Name,
	SUM(S.sales_amount) AS TOTAL_SALES
FROM gold.fact_sales S
LEFT JOIN gold.dim_product P
ON S.product_key = P.product_key
GROUP BY P.product_name
ORDER BY SUM(S.sales_amount);

-- Find the top 10 customers with highest revenue
SELECT TOP 10
    C.customer_id,
    C.FIRST_NAME + ' ' + C.LAST_NAME AS Customer_name,
    SUM(S.sales_amount) AS total_sales
FROM gold.fact_sales S
LEFT JOIN gold.dim_customers C
    ON S.customer_key = C.customer_key
GROUP BY C.customer_id, C.FIRST_NAME, C.LAST_NAME
ORDER BY total_sales DESC;

-- 3 customers with fewest orders placed
SELECT TOP 3
    C.customer_id,
    C.FIRST_NAME + ' ' + C.LAST_NAME AS Customer_name,
    COUNT(DISTINCT S.order_number) AS total_orders
FROM gold.fact_sales S
LEFT JOIN gold.dim_customers C
    ON S.customer_key = C.customer_key
GROUP BY C.customer_id, C.FIRST_NAME, C.LAST_NAME
ORDER BY total_orders ASC;

--#END OF EDA 1#--
