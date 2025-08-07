/*
=================================================================================================
PRODUCT REPORT
=================================================================================================
Purpose:
	- This report consolidates key product metrics and behaviours.

Highlights:
	1. Gather essential fields such as productname, category, subcategory and cost.
	2. Segments products by revenue to identity High-Performers, Mid-Range, or Low-Performers.
	3. Aggregate product level metrics:
		- total orders
		- total slaes 
		- total quantity sold
		- total customers (unique)
		- customer_history (in months)
	4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
=================================================================================================
*/

USE datawarehouse;
GO
IF OBJECT_ID ('gold.report_products', 'V') IS NOT NULL
	DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS
-- Base Query: Retrieves core columns from fact sales and dim products
WITH base_query AS (
	SELECT
		S.order_number,
		S.order_date,
		S.customer_key,
		S.sales_amount,
		S.quantity,
		P.product_key,
		P.product_name,
		P.category,
		P.sub_category,
		P.cost
	FROM gold.fact_sales S
	LEFT JOIN gold.dim_product P
	ON  S.product_key = P.product_key
	WHERE S.order_date IS NOT NULL
),

PRODUCT_AGGREGATIONS as (

	SELECT 
		PRODUCT_KEY,
		PRODUCT_NAME,
		CATEGORY,
		SUB_CATEGORY,
		COST,
		DATEDIFF(MONTH, MIN(ORDER_DATE), MAX(ORDER_DATE)) AS CUSTOMER_HISTORY,
		MAX(ORDER_DATE) AS LAST_SALE_DATE,
		COUNT(DISTINCT ORDER_NUMBER) AS TOTAL_ORDERS,
		COUNT(DISTINCT CUSTOMER_KEY) AS TOTAL_CUSTOMERS,
		SUM(SALES_AMOUNT) AS TOTAL_SALES,
		SUM(QUANTITY) AS TOTAL_QUANTITY,
		ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
	FROM base_query

	GROUP BY 
		PRODUCT_KEY,
		PRODUCT_NAME,
		CATEGORY,
		SUB_CATEGORY,
		COST
)

SELECT 
	PRODUCT_KEY,
	PRODUCT_NAME,
	CATEGORY,
	SUB_CATEGORY,
	COST,
	LAST_SALE_DATE,
	DATEDIFF(MONTH, LAST_SALE_DATE, GETDATE()) AS RECENCY_IN_MONTHS,
	CASE 
		WHEN TOTAL_SALES > 50000 THEN 'High-performer'
		WHEN TOTAL_SALES >= 10000 THEN 'Mid-Range'
		ELSE 'Low-performer'
	END AS PRODUCT_SEGMENT,
	CUSTOMER_HISTORY,
	TOTAL_ORDERS,
	TOTAL_CUSTOMERS,
	TOTAL_SALES,
	TOTAL_QUANTITY,
	AVG_SELLING_PRICE,
	CASE
		WHEN TOTAL_ORDERS = 0 THEN 0
		ELSE TOTAL_SALES/ TOTAL_ORDERS
	END AS AVG_ORDER_REVENUE,
	CASE 
		WHEN CUSTOMER_HISTORY = 0 THEN TOTAL_SALES
		ELSE TOTAL_SALES / CUSTOMER_HISTORY 
	END AS AVG_MONTHLY_REVENUE

	FROM PRODUCT_AGGREGATIONS
	

