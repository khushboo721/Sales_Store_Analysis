create database sql_project_sales

use sql_project_sales

CREATE TABLE store_sales (
transaction_id VARCHAR(15),
customer_id VARCHAR(15),
customer_name VARCHAR(30),
customer_age INT,
gender VARCHAR(15),
product_id VARCHAR(15),
product_name VARCHAR(15),
product_category VARCHAR(15),
quantiy INT,
prce FLOAT,
payment_mode VARCHAR(15),
purchase_date DATE,
time_of_purchase TIME,
status VARCHAR(15)
);

-- data imported by bulk insert method
SET DATEFORMAT dmy
BULK INSERT store_sales
FROM 'D:\sales_data_sql\sales_store_dataset.csv'
	WITH (
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='\n'
	);

	-- Data Cleaning 

-- Step 1 : Checking Duplicates

SELECT transaction_id
from store_sales
GROUP BY transaction_id
HAVING COUNT(transaction_id) >1


--Duplicates found 
--TXN240646
--TXN342128
--TXN855235
--TXN981773

-- Checking Duplicates by Index Function

WITH CTE AS (
SELECT *,
    ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id) AS Row_Num
FROM store_sales
)
--DELETE FROM CTE      -- Deleting Duplicates 
--WHERE Row_Num=2
SELECT * FROM CTE
WHERE transaction_id IN ('TXN240646','TXN342128','TXN855235','TXN981773')

--Correcting Headers
EXEC sp_rename'store_sales.quantiy','quantity','COLUMN'

EXEC sp_rename'store_sales.prce','price','COLUMN'

select * from store_sales

-- checking Datatype
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='store_sales'

-- Checking Null Count

DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, 
    COUNT(*) AS NullCount 
    FROM ' + QUOTENAME(TABLE_SCHEMA) + '.store_sales
    WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL', 
    ' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'store_sales';

-- Executing Dynamic SQL
EXEC sp_executesql @SQL;

--Treating Null Values

SELECT *
FROM store_sales
WHERE transaction_id IS NULL
OR
customer_id IS NULL
OR
customer_name IS NULL
OR
customer_age IS NULL
OR
gender IS NULL
OR
product_id IS NULL
OR
product_name IS NULL
OR
product_category IS NULL
OR
quantity IS NULL
or
payment_mode is null
or
purchase_date is null
or 
status is null
or 
price is null

DELETE FROM store_sales
WHERE  transaction_id IS NULL

SELECT * FROM store_sales 
Where Customer_name='Ehsaan Ram'


UPDATE store_sales
SET customer_id='CUST9494'
WHERE transaction_id='TXN977900'

SELECT * FROM store_sales
Where Customer_name='Damini Raju'

UPDATE store_sales
SET customer_id='CUST1401'
WHERE transaction_id='TXN985663'

SELECT * FROM store_sales
Where Customer_id='CUST1003'

UPDATE store_sales
SET customer_name='Mahika Saini',customer_age=35,gender='Male'
WHERE transaction_id='TXN432798'


SELECT * FROM store_sales

-- Data Cleaning

SELECT DISTINCT gender
FROM store_sales


UPDATE store_sales
SET gender='M'
WHERE gender='Male'

UPDATE store_sales
SET gender='F'
WHERE gender='Female'

SELECT DISTINCT payment_mode
FROM store_sales

UPDATE store_sales
SET payment_mode='Credit Card'
WHERE payment_mode='CC'

--Q1. What are the top 5 most selling products by quantity?

SELECT * FROM store_sales
SELECT DISTINCT status
from store_sales

SELECT TOP 5 product_name, SUM(quantity) AS total_quantity_sold
FROM store_sales
WHERE status='delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC

--Business Problem: We don't know which products are most in demand.
--Business Impact: Helps prioritize stock and boost sales through targeted promotions.


--Q2. Which products are most frequently cancelled?

SELECT TOP 5 product_name, COUNT(*) AS total_cancelled
FROM store_sales
WHERE status='cancelled'
GROUP BY product_name
ORDER BY total_cancelled DESC

--Business Problem: Frequent cancellations affect revenue and customer trust.
--Business Impact: Identify poor-performing products to improve quality or remove from catalog.



--Q3. What time of the day has the highest number of purchases?

select * from store_sales
	
	SELECT 
		CASE 
			WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
			WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
			WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
			WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
		END AS time_of_day,
		COUNT(*) AS total_orders
	FROM store_sales
	GROUP BY 
		CASE 
			WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
			WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
			WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
			WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
		END
ORDER BY total_orders DESC

--Business Problem Solved: Find peak sales times.
--Business Impact: Optimize staffing, promotions, and server loads.



--Q4. Who are the top 5 highest spending customers?

SELECT * FROM store_sales

SELECT TOP 5 customer_name,
	FORMAT(SUM(price*quantity),'C0','en-IN') AS total_spend
FROM store_sales
GROUP BY customer_name
ORDER BY SUM(price*quantity) DESC

--Business Problem Solved: Identify VIP customers.
--Business Impact: Personalized offers, loyalty rewards, and retention.



--Q5. Which product categories generate the highest revenue?

SELECT * FROM store_sales

SELECT 
	product_category,
	FORMAT(SUM(price*quantity),'C0','en-IN') AS Revenue
FROM store_sales
GROUP BY product_category
ORDER BY SUM(price*quantity) DESC

--Business Problem Solved: Identify top-performing product categories.
--Business Impact: Refine product strategy, supply chain, and promotions.
--allowing the business to invest more in high-margin or high-demand categories



--Q6. What is the return/cancellation rate per product category?

SELECT * FROM store_sales
--cancellation
SELECT product_category,
	FORMAT(COUNT(CASE WHEN status='cancelled' THEN 1 END)*100.0/COUNT(*),'N3')+' %' AS cancelled_percent
FROM store_sales 
GROUP BY product_category
ORDER BY cancelled_percent DESC

--Return
SELECT product_category,
	FORMAT(COUNT(CASE WHEN status='returned' THEN 1 END)*100.0/COUNT(*),'N3')+' %' AS returned_percent
FROM store_sales
GROUP BY product_category
ORDER BY returned_percent DESC

--Business Problem Solved: Monitor dissatisfaction trends per category.
---Business Impact: Reduce returns, improve product descriptions/expectations.
--Helps identify and fix product or logistics issues.

-----------------------------------------------------------------------------------------------------------
--Q7. What is the most preferred payment mode?

SELECT * FROM store_sales

SELECT payment_mode, COUNT(payment_mode) AS total_count
FROM store_sales
GROUP BY payment_mode
ORDER BY total_count desc


--Business Problem Solved: Know which payment options customers prefer.
--Business Impact: Streamline payment processing, prioritize popular modes.

-----------------------------------------------------------------------------------------------------------

--Q8. How does age group affect purchasing behavior?

SELECT * FROM store_sales
--SELECT MIN(customer_age) ,MAX(customer_age)
--from sales

SELECT 
	CASE	
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
		ELSE '51+'
	END AS customer_age,
	FORMAT(SUM(price*quantity),'C0','en-IN') AS total_purchase
FROM store_sales 
GROUP BY CASE	
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
		ELSE '51+'
	END
ORDER BY SUM(price*quantity) DESC

--Business Problem Solved: Understand customer demographics.
--Business Impact: Targeted marketing and product recommendations by age group.

-----------------------------------------------------------------------------------------------------------
--9. What’s the monthly sales trend?

SELECT * FROM store_sales

SELECT 
	FORMAT(purchase_date,'yyyy-MM') AS Month_Year,
	FORMAT(SUM(price*quantity),'C0','en-IN') AS total_sales,
	SUM(quantity) AS total_quantity
FROM store_sales
GROUP BY FORMAT(purchase_date,'yyyy-MM')

--Business Problem: Sales fluctuations go unnoticed.
--Business Impact: Plan inventory and marketing according to seasonal trends.


--🔎 10. Are certain genders buying more specific product categories?

SELECT * from store_sales

SELECT gender,product_category,COUNT(product_category) AS total_purchase
FROM store_sales
GROUP BY gender,product_category
ORDER BY gender

--Business Problem Solved: Gender-based product preferences.
--Business Impact: Personalized ads, gender-focused campaigns.

