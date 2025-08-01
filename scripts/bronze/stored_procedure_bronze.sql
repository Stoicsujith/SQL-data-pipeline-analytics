/*
=========================================================
CREATING STORED PROCEDURE TO LOAD DATA into BRONZE LAYER 
=========================================================

SCRIPT PURPOSE
	This script loads data from csv files to the table
	It performs the following operations:
		trucating the table to make the table empty
		BULK INSERT is used to load data
		using try & catch to handle an error
		shows execution time for each table execution and the whole bronze_layer

Warning:
	make sure to check any data exists in the table 
	this scrip truncates all data and load new data from source

TO USE:
	EXEC SCHMEA.NAME (EXEC bronze.load_bronze)
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze as
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
BEGIN TRY
		SET @batch_start_time = GETDATE();
		
		PRINT '===============================================';
		PRINT 'BRONZE LAYER EXECUTION INITIATED';
		PRINT '===============================================';
	

		PRINT '-----------------------------------------------';
		PRINT 'LOADING CRM FILES';
		PRINT '-----------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> TRUNCATING TABLE: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> INSERTING DATA INTO: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'Enter/file/path'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) as NVARCHAR) + 'SECONDS';
		PRINT '-------------';

		SET @start_time = GETDATE();
		PRINT '>> TRUNCATING TABLE: bronze.crm_sales_details';

		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT '>> INSERTING DATE INTO: bronze.crm_sales_details';
		BULK INSERT bronze.crm_cust_info
		FROM 'Enter/file/path'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) as NVARCHAR) + 'SECONDS';
		PRINT '-------------';

		SET @start_time = GETDATE();
		PRINT '>> TRUNCATING TABLE: bronze.crm_sales_details';

		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT '>> INSERTING DATE INTO: bronze.crm_sales_details';
		BULK INSERT bronze.crm_prd_info
		FROM 'Enter/file/path'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) as NVARCHAR) + 'SECONDS';
		PRINT '-------------';

		PRINT '-----------------------------------------------';
		PRINT 'LOADING ERP FILES';
		PRINT '-----------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> TRUNCATING TABLE: bronze.crm_sales_details';

		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT '>> INSERTING DATE INTO: bronze.crm_sales_details';
		BULK INSERT bronze.erp_cust_az12
		FROM 'Enter/file/path'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) as NVARCHAR) + 'SECONDS';
		PRINT '-------------';

		SET @start_time = GETDATE();
		PRINT '>> TRUNCATING TABLE: bronze.crm_sales_details';

		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT '>> INSERTING DATE INTO: bronze.crm_sales_details';
		BULK INSERT bronze.erp_loc_a101
		FROM 'Enter/file/path'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) as NVARCHAR) + 'SECONDS';
		PRINT '-------------';

		SET @start_time = GETDATE();
		PRINT '>> TRUNCATING TABLE: bronze.crm_sales_details';

		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT '>> INSERTING DATE INTO: bronze.crm_sales_details';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'Enter/file/path'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();

		PRINT 'LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) as NVARCHAR) + 'SECONDS';
		PRINT '-------------';

		SET @batch_end_time = GETDATE();
		PRINT '=======================================';
		PRINT 'EXECUTION OF BRONZE LAYER COMPLETED';
		PRINT '  - TOTAL_LOAD_DURATION: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) as NVARCHAR) + 'SECONDS';
		PRINT '=======================================';
	END TRY
	BEGIN CATCH
	    PRINT '=======================================';
		PRINT 'ERROR OCCURED DURING EXECUTIG BRONZE LAYER';
		PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
		PRINT 'ERROR MESSAGE' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '=======================================';
	END CATCH
END 
