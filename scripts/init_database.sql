/*
===================================================
Creating database and schemas
===================================================

script purpose:
     The script create a database called 'Datawarehouse' 
     It checks if it already exists, if database exists it is dropped and recreated
     And the script also creates three schemas Bronze, Silver and Gold

Warning:
    Running this script will remove the 'datawarehouse' database if already exists
    Which leads to deleteion of data's which is already stored in the database
    Make sure to check whether the database exists or not
*/

USE master;
GO
-- go is a command that signals the end of the batch of T-SQL statement

--Drop and recreate database "datawarehouse" if exists
--If a database named DataWarehouse exists, then force it into single-user mode, kick out everyone, and delete it immediately.
IF EXISTS (SELECT 1 FROM  sys.databases WHERE name = 'DataWarehouse')
Begin 
  ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE DataWarehouse;
END;
GO

--Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Creating Schemas
CREATE SCHEMA bronze;
GO


CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
