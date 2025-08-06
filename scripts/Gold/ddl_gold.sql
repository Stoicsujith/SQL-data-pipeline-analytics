/*
===============================================================================
Gold Layer Views - DDL Script
===============================================================================
Purpose:
    Defines final dimension and fact views (Star Schema) in the Gold layer.
    Transforms and enriches Silver layer data into clean, business-ready views.

Usage:
    Use these views directly for reporting and analytics.
===============================================================================
*/


USE datawarehouse;
GO
/*
=======================================
Creating Dimension: gold.dim_customers
=======================================
*/
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS

SELECT  
	ROW_NUMBER() OVER(ORDER BY CST_ID) AS customer_key,
	A1.cst_id customer_id,
	A1.cst_key AS customer_number,
	A1.cst_firstname AS first_name,
	A1.cst_lastname last_name,
	A3.CNTRY AS country,
	CASE WHEN A1.cst_gndr != 'N/A' THEN A1.cst_gndr
		ELSE COALESCE(A2.GEN, 'N/A')
	END AS gender,
	A1.cst_marital_status AS marital_status,
	A2.BDATE AS birthdate,
	A1.cst_create_date AS create_date
FROM silver.crm_cust_info A1
LEFT JOIN SILVER.erp_cust_az12 A2
ON A1.cst_key = A2.CID
LEFT JOIN silver.erp_loc_a101 A3
ON A1.cst_key = A3.CID;
GO

/*
======================================
Creating Dimension: gold.dim_product
======================================
*/

IF OBJECT_ID ('gold.dim_product', 'V') IS NOT NULL
	DROP VIEW gold.dim_product
GO 

CREATE VIEW gold.dim_product AS

SELECT 
	ROW_NUMBER() OVER(ORDER BY A1.PRD_START_DT, A1.PRD_KEY) AS product_key,
	A1.prd_id AS product_id,
	A1.prd_key AS product_number,
	A1.prd_nm AS product_name,
	A1.prd_cat AS category_id,
	A2.CAT AS category,
	A2.SUBCAT AS sub_category,
	A2.MAINTENANCE as maintenance,
	A1.prd_cost as cost,
	A1.prd_line as product_line,
	A1.prd_start_dt as start_date
FROM silver.crm_prd_info A1
LEFT JOIN SILVER.erp_px_cat_g1v2 A2
ON A1.prd_cat = A2.ID
WHERE A1.prd_end_dt IS NULL;
GO

/*
======================================
Creating Dimension: gold.fact_sales
======================================
*/

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO 

CREATE VIEW gold.fact_sales AS 

SELECT 
	S1.sls_ord_num AS order_number,
	prd.product_key,
	cr.customer_key,
	S1.sls_order_dt AS order_date,
	S1.sls_ship_dt AS ship_date,
	S1.sls_due_dt AS due_date,
	S1.sls_sales AS sales_amount,
	S1.sls_quantity AS quantity,
	S1.sls_price AS price
FROM silver.crm_sales_details S1
LEFT JOIN gold.dim_product prd
ON S1.sls_prd_key = prd.product_number
LEFT JOIN gold.dim_customers cr
ON S1.sls_cust_id = cr.customer_id;
