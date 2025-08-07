# SQL Data Warehouse Project – Medallion Architecture

## 📌 Project Objective

This project demonstrates the end-to-end development of a data warehouse using the **Medallion Architecture** in **Microsoft SQL Server**. It transforms raw CSV files into clean, business-ready datasets through a multi-layered SQL pipeline, culminating in a **Star Schema** design.

---

## 🗂️ Data Overview

- **Data Sources**: CRM & ERP systems  
- **Tables Used**:  
  - CRM: cust_info, prd_info, sales_details
  - ERP: cust_az12, loc_a101, px_cat_g1v2  
- **Source**: CSV FILES

---

## 🧱 Architecture Overview

- **Layers Used**:  
  - `Bronze`: Raw data ingestion  
  - `Silver`: Cleaned and transformed data  
  - `Gold`: Final reporting views  
- **Schema**: Star Schema  
- **Tech Stack**:  
  - Microsoft SQL Server  
  - SQL Stored Procedures  
  - SQL Views  
- **Automation**:  
  - Stored procedures used for data loading and transformation  
  - Execution tracking via timestamps and error handling

---

## 🔄 Layer Breakdown

### 🟤 Bronze Layer

- **Purpose**: Raw ingestion from CSV files into staging tables  
- **Implementation**:  
  - Truncates existing tables  
  - Loads using `BULK INSERT`  
  - Captures duration logs for each table  
  - Handles errors using `TRY...CATCH` blocks  
- **Procedure**: `bronze.load_bronze`

### ⚪ Silver Layer

- **Purpose**: Data cleaning and transformation  
- **Key Tasks**:
  - Deduplication using `ROW_NUMBER()`  
  - Name formatting (capitalization, trimming)  
  - Standardization of gender, marital status, product types  
  - Handling of nulls, zeroes, and incorrect dates  
  - Enrichment via ERP tables  
- **Procedure**: `silver.load_silver`

### 🟡 Gold Layer

- **Purpose**: Final reporting layer with business-ready views  
- **Views Created**:
  - `gold.dim_customers`
  - `gold.dim_product`
  - `gold.fact_sales`
- **Design**: Star Schema with 1 fact and 2 dimensions  
- **Use**: Designed for direct querying by reporting and analytics layers

---
### 🔍 Exploratory Data Analysis (EDA)

As part of the Gold Layer, two exploratory analyses were conducted using pure SQL to extract key business insights.

#### 📌 Customer Analysis
- Counted customers by gender and marital status combinations  
- Identified top countries by customer count  
- Analyzed birth year distribution to understand customer age groups  
- Verified completeness of customer attributes (null checks, ‘N/A’ values)

#### 📌 Product Analysis
- Counted products by category and sub-category  
- Identified product types with the highest number of sales  
- Analyzed price distribution to spot potential outliers or misclassified products  
- Merged CRM and ERP product records to validate product catalog consistency

---


## 📊 Visual Diagrams

- `data_flow.png` – Visualizes end-to-end flow from source to gold
- `data_integration.png` – Shows how CRM and ERP datasets were merged
- `data_mart.png` – Final star schema structure with fact and dimensions

---

## 🚀 Getting Started

### Requirements
- Microsoft SQL Server (2019 or later recommended)
- SQL Server Management Studio (SSMS)
- The 6 source CSV files in local or accessible file paths

### How to Run
1. Create database: `datawarehouse`
2. Execute table DDL scripts for bronze/silver/gold layers
3. Run `bronze.load_bronze` to ingest raw data
4. Run `silver.load_silver` to transform into cleaned data
5. Execute gold view scripts for reporting layer

---

## ✅ Outcome

- Raw, inconsistent source data was transformed into a clean, enriched dataset using SQL-only data pipeline.
- Final Gold Layer provides a reliable reporting layer following modern data warehousing best practices.
- Designed for scalability and extensibility to add more dimensions/facts.
  
---

## 🧠 Future Improvements

- Add automation via SQL Agent or Airflow
- Integrate with BI tools like Power BI or Tableau
- Introduce incremental data loading and partitioning
- Add data quality validation layer

---

## 👨‍💻 Author

- **Project by**: Sujith MP  
- **Tech Stack**: SQL Server, T-SQL, GitHub  
- **Source Inspiration**: [Baara – YouTube Tutorial on Data Warehousing](https://youtu.be/SSKVgrwhzus?si=SuQBLImJlHk-E-RX)

---
