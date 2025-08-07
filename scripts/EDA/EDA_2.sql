/*
===============================================================================
EDA Part 2 - SQL Script
===============================================================================
Purpose:
    Advanced EDA on the Gold Layer to extract behavioral, temporal, and 
    performance insights.

Scope:
    - Time Trends:
        > Year-over-year sales and customer growth
        > Monthly seasonality and average price shifts

    - Cumulative Metrics:
        > Monthly sales totals, running totals, and moving averages

    - Performance Benchmarking:
        > Product-level sales vs. historical averages
        > YoY performance classification: Above / Average / Below

    - Part-to-Whole Analysis:
        > Sales and order share by category and region
        > Contribution breakdowns (%)

    - Segmentation:
        > Product cost-based buckets
        > Customer cohorts: VIP, Regular, New

Usage:
    Identifies trends, benchmarks product performance, and segments entities 
    for targeted strategies.
===============================================================================
*/

USE datawarehouse;
GO

--============================
-- CHANGE OVER TIME ANALYSIS
--============================

-- Finding the trend on sales by year
SELECT 
	YEAR(ORDER_DATE) AS order_year,
	SUM(sales_amount) AS total_sales,
	COUNT(customer_key) AS total_customers
FROM gold.fact_sales S
WHERE ORDER_DATE IS NOT NULL
GROUP BY YEAR(ORDER_DATE) 
ORDER BY YEAR(ORDER_DATE) ASC;

-- Find the seasonality of sales by month
SELECT 
	MONTH(ORDER_DATE) AS month_id,
	FORMAT(ORDER_DATE, 'MMM') AS order_month,
	COUNT(customer_key) AS total_customers,
	SUM(sales_amount) AS total_sales
FROM gold.fact_sales S
WHERE ORDER_DATE IS NOT NULL
GROUP BY MONTH(ORDER_DATE), FORMAT(ORDER_DATE, 'MMM')
ORDER BY MONTH(ORDER_DATE) ASC;

-- does the price increased for any product by year
SELECT *
FROM (
    SELECT 
        YEAR(S.ORDER_DATE) AS order_year,
        P.PRODUCT_NAME AS product_name,
        AVG(S.sales_amount) AS avg_price
    FROM gold.fact_sales S
    LEFT JOIN gold.dim_product P
        ON S.PRODUCT_KEY = P.PRODUCT_KEY 
    WHERE S.ORDER_DATE IS NOT NULL
    GROUP BY YEAR(S.ORDER_DATE), P.PRODUCT_NAME
) AS sub
WHERE product_name IN (
    SELECT product_name
    FROM (
        SELECT 
            P.PRODUCT_NAME,
            AVG(S.sales_amount) AS avg_price
        FROM gold.fact_sales S
        LEFT JOIN gold.dim_product P
            ON S.PRODUCT_KEY = P.PRODUCT_KEY 
        WHERE S.ORDER_DATE IS NOT NULL
        GROUP BY YEAR(S.ORDER_DATE), P.PRODUCT_NAME
    ) grouped
    GROUP BY product_name
    HAVING MIN(avg_price) <> MAX(avg_price)
)
ORDER BY product_name, order_year;

--=============================
-- CUMULATIVE MEASURE ANLAYSIS
--=============================

-- caluculate the total sales per month
-- and running total of sales over time
SELECT 
    order_date,
    total_sales,
    SUM(total_sales) OVER(PARTITION BY ORDER_DATE ORDER BY order_date) AS running_total,
    AVG(avg_price) OVER(PARTITION BY ORDER_DATE ORDER BY ORDER_DATE) AS moving_average
FROM (
SELECT 
    DATETRUNC(MONTH, ORDER_DATE) AS order_date,
    SUM(SALES_AMOUNT) AS total_sales,
    AVG(PRICE) AS avg_price
FROM gold.fact_sales
WHERE ORDER_DATE IS NOT NULL
GROUP BY DATETRUNC(MONTH, ORDER_DATE)) AS R;

--=========================
--  Performance Analysis
--=========================

-- Analyze the yearly performance of product by comparing their sales
-- to both average saless performance of product and previous year's sale
WITH YEARLY_PRODUCT_SALES AS(
SELECT 
    YEAR(S.ORDER_DATE)  AS ORDER_YEAR,
    P.product_name,
    SUM(S.SALES_AMOUNT) AS current_sales
FROM gold.fact_sales S
LEFT JOIN gold.dim_product P
ON  S.product_key = P.PRODUCT_KEY
WHERE ORDER_DATE IS NOT NULL
GROUP BY YEAR(ORDER_DATE) ,  
    P.product_name
) 

SELECT 
    ORDER_YEAR,
    PRODUCT_NAME,
    CURRENT_SALES,
    AVG(CURRENT_SALES) OVER(PARTITION BY PRODUCT_NAME) AS AVG_SALES,
    CASE 
        WHEN CURRENT_SALES - AVG(CURRENT_SALES) OVER(PARTITION BY PRODUCT_NAME) < 0 THEN 'Below avg'
        WHEN CURRENT_SALES - AVG(CURRENT_SALES) OVER(PARTITION BY PRODUCT_NAME) > 0 THEN 'Above avg'
        ELSE 'Avg'
    END AS AVG_FLAG,
    LAG(CURRENT_SALES) OVER(PARTITION BY PRODUCT_NAME ORDER BY ORDER_YEAR) AS PY_SALES,
    CASE    
        WHEN CURRENT_SALES - LAG(CURRENT_SALES) OVER(PARTITION BY PRODUCT_NAME ORDER BY ORDER_YEAR) < 0 THEN 'Decrease'
        WHEN CURRENT_SALES - LAG(CURRENT_SALES) OVER(PARTITION BY PRODUCT_NAME ORDER BY ORDER_YEAR) > 0 THEN 'Increase'
        ELSE 'No Change'
    END AS PY_CHANGE
FROM YEARLY_PRODUCT_SALES
ORDER BY PRODUCT_NAME, ORDER_YEAR;

--=========================
-- Part to Whole Analysis
--=========================

-- Which categories contributes the most to overall sales
WITH SALES AS (
SELECT 
    P.CATEGORY,
    SUM(S.SALES_AMOUNT) AS total_sales
FROM gold.fact_sales S
LEFT JOIN gold.dim_product P
ON S.product_key = P.product_key
GROUP BY CATEGORY
)

SELECT 
    CATEGORY,
    TOTAL_SALES,
    SUM(TOTAL_SALES) OVER() AS Overall_sales,
    FORMAT(ROUND((total_sales * 1.0 / SUM(total_sales) OVER()) * 100, 2), 'N2') + '%' AS Percent_sales
FROM SALES
GROUP BY CATEGORY, total_sales
ORDER BY TOTAL_SALES DESC;


---- Which categories contributes the most to overall sales
WITH SALES AS (
SELECT 
    P.CATEGORY,
    COUNT(S.order_number) AS total_orders
FROM gold.fact_sales S
LEFT JOIN gold.dim_product P
ON S.product_key = P.product_key
GROUP BY CATEGORY
)

SELECT 
    CATEGORY,
    TOTAL_ORDERS,
    SUM(TOTAL_ORDERS) OVER() AS Overall_sales,
    FORMAT(ROUND((total_orders * 1.0 / SUM(total_orders) OVER()) * 100, 2), 'N2') + '%' AS Percent_sales
FROM SALES
GROUP BY CATEGORY, total_orders
ORDER BY TOTAL_ORDERS DESC;

-- Which countries contributes the most CUSTOMERS
WITH COUNTRY AS (
SELECT 
    C.COUNTRY,
    COUNT(S.CUSTOMER_KEY) AS total_customers
FROM GOLD.fact_sales S
LEFT JOIN gold.dim_customers C
ON S.customer_key = C.customer_key
GROUP BY COUNTRY
)

SELECT 
    COUNTRY,
    TOTAL_CUSTOMERS,
    SUM(TOTAL_CUSTOMERS) OVER() AS  OVERALL_CUSTOMERS,
    FORMAT(ROUND((TOTAL_CUSTOMERS * 1.0) / SUM(TOTAL_CUSTOMERS) OVER() * 100, 2), 'N2') + '%' AS CUSTOMER_PERCENTAGE
FROM COUNTRY
ORDER BY TOTAL_CUSTOMERS DESC;

--=====================
-- DATA SEGMENTATION
--=====================

-- Segment product in cost ranges
-- count how many product fall into each segment
WITH COST AS (
SELECT 
	product_key,
	product_name,
	cost,
	CASE
		WHEN COST < 100 THEN 'Below 100'
		WHEN COST BETWEEN 100 AND 500 THEN '100-500'
		WHEN COST BETWEEN 500 AND 1000 THEN '500-1000'
		ELSE 'Above 1000'
	END AS COST_RANGE
FROM gold.dim_product)

SELECT 
	COST_RANGE,
	COUNT(PRODUCT_KEY) AS PRODUCT_COUNT
FROM COST 
GROUP BY COST_RANGE
ORDER BY PRODUCT_COUNT DESC;

--Grouping customers based on their spending_behaviour
-- VIP: Customers with atleast 12 months of history and spending more than $5000
-- Regular: Customers with atleast 12 months of history and spending atleast $5000 or less
-- New: Customers with a history of lessthan 12 months
-- Find the total number of customers by each group
WITH CUSTOMERS AS (
SELECT 
	C.customer_key,
	C.first_name + ' ' + C.last_name AS Customer_Name,
	SUM(S.sales_amount) AS Total_Spending,
	DATEDIFF(MONTH, MIN(ORDER_DATE), MAX(ORDER_DATE)) AS Customers_history,
	CASE 
		WHEN DATEDIFF(MONTH, MIN(ORDER_DATE), MAX(ORDER_DATE)) >= 12 AND SUM(S.sales_amount) > 5000
		THEN 'VIP'
		WHEN DATEDIFF(MONTH, MIN(ORDER_DATE), MAX(ORDER_DATE)) >= 12 AND SUM(S.sales_amount) <= 5000
		THEN 'Regular'
		ELSE 'New'
	END AS CUSTOMER_RANGE
FROM gold.fact_sales S
LEFT JOIN gold.dim_customers C
ON S.customer_key = C.customer_key
GROUP BY C.customer_key, C.first_name, C.last_name)

SELECT 
	CUSTOMER_RANGE,
	COUNT(customer_key) AS Total_Customer
FROM CUSTOMERS
GROUP BY CUSTOMER_RANGE
ORDER BY Total_Customer DESC;

--#END OF EDA PART 2#--

