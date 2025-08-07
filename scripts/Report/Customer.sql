USE datawarehouse;
GO

/*
=================================================================================
 CUSTOMER REPORT
=================================================================================
Purpose:
	- This report consolidates key customer metrics and behaviors

Highlights:
	1. Gather essential fields such as names, ages, and transaction details.
	2. Segment customers into categories (VIP, Regular, New) and age groups
	3. Aggregate customer - level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- customer_history (in months)
	4. Calculates valuable KPIs:
		- recency  (months since last order)
		- average order value
		- average monthly spend
=================================================================================
*/
IF OBJECT_ID ('gold.report_customer', 'V') IS NOT NULL
	DROP VIEW gold.report_customer;
GO

CREATE VIEW gold.report_customer AS
-- Base Query: Retrieves core columns from fact sales and dim customers
WITH BASE_QUERY AS (
SELECT 
	S.order_number,
	S.product_key,
	S.order_date,
	S.sales_amount,
	S.quantity,
	C.customer_key,
	C.customer_number,
	C.first_name + ' ' + C.last_name AS customer_name,
	DATEDIFF(YEAR, C.BIRTHDATE, GETDATE()) AS age
FROM gold.fact_sales S
LEFT JOIN gold.dim_customers C
ON S.customer_key = C.customer_key
WHERE ORDER_DATE IS NOT NULL)

, Customer_aggregation as (
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(QUANTITY) AS total_quantity,
	COUNT(DISTINCT PRODUCT_KEY) AS total_products,
	MAX(ORDER_DATE) AS last_order_date,
	DATEDIFF(MONTH, MIN(ORDER_DATE), MAX(ORDER_DATE)) AS customer_history
FROM BASE_QUERY
GROUP BY customer_key, customer_number, customer_name, age)

SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE 
		WHEN age < 20 THEN 'Under 20'
		WHEN age BETWEEN 20 AND 29 THEN '20-29'
		WHEN age BETWEEN 30 AND 39 THEN '30-39'
		WHEN age BETWEEN 40 AND 49 THEN '40-49'
		ELSE 'Above 50'
	END AS age_group,
	CASE 
		WHEN customer_history >= 12 AND total_sales > 5000
		THEN 'VIP'
		WHEN customer_history >= 12 AND total_sales <= 5000
		THEN 'Regular'
		ELSE 'New'
	END AS customer_segment,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,
	customer_history,
	CASE 
	 WHEN total_sales = 0 THEN 0
	 ELSE total_sales / total_orders 
	END AS avg_order_value,
	CASE
		WHEN customer_history = 0 THEN total_sales
		ELSE customer_history / total_sales 
	END AS avg_monthly_spend
FROM Customer_aggregation
