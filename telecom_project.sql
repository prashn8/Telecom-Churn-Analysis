CREATE TABLE customers (
    customerID VARCHAR(20) PRIMARY KEY,
    gender VARCHAR(10),
    SeniorCitizen INT,
    Partner VARCHAR(5),
    Dependents VARCHAR(5)
);
COPY customers
FROM 'D:\SQL_PROJECTS\telecom_data_project\customers.csv'
DELIMITER ','
CSV HEADER;

CREATE TABLE services (
    customerID VARCHAR(20),
    PhoneService VARCHAR(20),
    MultipleLines VARCHAR(30),
    InternetService VARCHAR(30),
    OnlineSecurity VARCHAR(30),
    OnlineBackup VARCHAR(30),
    DeviceProtection VARCHAR(30),
    TechSupport VARCHAR(30),
    StreamingTV VARCHAR(30),
    StreamingMovies VARCHAR(30)
);

COPY services
FROM 'D:\SQL_PROJECTS\telecom_data_project\services.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM billing;
SELECT * FROM services;
SELECT * FROM customers;

CREATE TABLE billing
    (customerID VARCHAR(20),
    tenure INT,
    Contract VARCHAR(30),
    PaperlessBilling VARCHAR(5),
    PaymentMethod VARCHAR(50),
    MonthlyCharges NUMERIC(10,2),
    TotalCharges VARCHAR(20),
    Churn VARCHAR(5)
);

COPY billing
FROM 'D:\SQL_PROJECTS\telecom_data_project\billing.csv'
DELIMITER ','
CSV HEADER;

---changing data type
ALTER TABLE billing
ALTER COLUMN totalcharges TYPE NUMERIC
USING NULLIF(TRIM(totalcharges), '')::NUMERIC;

---checking null value form customers table
SELECT *
FROM customers
WHERE customerID IS NULL
   OR customerID = '';
   
---checking null values form billing charges
SELECT totalcharges FROM billing 
WHERE totalcharges IS NULL;
   
---checking error value form customers table
SELECT DISTINCT gender FROM customers;

---checking error value form customers table
SELECT DISTINCT seniorcitizen FROM customers;

---checking the negative error numbers from billing table
SELECT tenure, monthlycharges
FROM billing 
WHERE tenure < 0 AND monthlycharges < 0;

---finding duplicate value
SELECT customerid, count(*) FROM customers
GROUP BY customerid 
HAVING COUNT(*) > 1;

---finding total customers
SELECT COUNT(customerid) FROM customers;

---finding total churned customers
SELECT count(*) FROM billing 
WHERE TRIM(LOWER(churn)) = 'yes';

---finding churn rate
WITH total_customers AS
	(SELECT
		COUNT(customerid) AS total_count,
		SUM(CASE
				WHEN TRIM(LOWER(churn)) = 'yes' THEN 1 
				ELSE 0
			END) AS churn_count
	FROM billing)

SELECT churn_count * 100 / total_count 
FROM total_customers AS churn rate;

---calculating total revenue.
SELECT SUM(totalcharges) AS total_revenue
FROM billing; 

---calculate average monthly charges.	
SELECT ROUND(AVG(monthlycharges), 02) AS avg_charges_monthly 
FROM billing;

---Analyze customer distribution by gender
SELECT 	gender, COUNT(*) 
FROM customers
GROUP BY gender;

---Analyze customer distribution by  contract type
SELECT contract, COUNT(*) 
FROM billing
GROUP BY contract;

---Analyze customer distribution by InterNet Services
SELECT internetservice, COUNT(*) 
FROM services
GROUP BY internetservice;

---Analyze customer distribution by Payment Meathod
SELECT PaymentMethod, COUNT(*) 
FROM billing
GROUP BY PaymentMethod;

---Analyze customer distribution by Senior Citizen 
SELECT seniorcitizen, COUNT(*) 
FROM customers
GROUP BY seniorcitizen;

---Determine which contract type has the highest churn.
SELECT contract, COUNT(*) AS churn_count
FROM billing
WHERE TRIM(LOWER(churn)) = 'yes'
GROUP BY contract;

---Determine which payment method is associated with the highest churn.
SELECT paymentmethod, COUNT(*) AS churn_count
FROM billing
WHERE TRIM(LOWER(churn)) = 'yes'
GROUP BY paymentmethod
ORDER BY churn_count DESC;

---Analyze churn across tenure groups.
SELECT tenure, COUNT(*) AS churn_count 
FROM billing
WHERE TRIM(LOWER(churn)) = 'yes'
GROUP BY tenure 
ORDER BY churn_count DESC

---Analyze revenue contribution by customer segment.
SELECT
	CASE 
		WHEN tenure < 12 THEN 'New Customer'
		WHEN tenure < 36 THEN 'Regular Customer'
		ELSE 'Loyal Customer'
		END AS custormer_segment,

		SUM(totalcharges) AS total_revenue

FROM billing
GROUP BY custormer_segment
ORDER BY total_revenue DESC;

---creating customer segment
WITH customer_segment AS
	(SELECT customerid, tenure,
		CASE 
			WHEN tenure < 12 THEN 'New Customer'
			WHEN tenure < 36 THEN 'Regular Customer'
			ELSE 'Loyal Customer'
			END AS custormer_segment
	FROM billing)
SELECT * FROM customer_segment

--- Use window functions for ranking and comparison.
WITH revenue_data AS
	(SELECT customerid,
	COALESCE(SUM(TotalCharges), 0)
	AS total_revenue
	FROM billing
	GROUP BY customerid),

comparision_data AS
	(SELECT customerid,
	total_revenue,
	LEAD(total_revenue) OVER(ORDER BY total_revenue DESC) 
	AS next_revenue,

	LEAD(total_revenue) OVER(ORDER BY total_revenue DESC) - total_revenue 
	AS revenue_diff
	
	FROM revenue_data),

ranked_data AS
	(SELECT customerid, 
	total_revenue, 
	revenue_diff, 
	DENSE_RANK() OVER(ORDER BY total_revenue DESC)
	AS rank_no
	FROM comparision_data)

SELECT * FROM ranked_data;

---Create business KPIs.
WITH churned_customers AS
	(SELECT 
		COUNT(customerid) AS total_customers, 
		SUM(
			CASE
				WHEN TRIM(LOWER(churn)) = 'yes'
				THEN 1 
				ELSE 0 
				END) 
				AS churn_customers,
		COALESCE(ROUND(SUM(TotalCharges),2),0) AS total_revenue,
		COALESCE(ROUND(AVG(MonthlyCharges),2),0) AS avg_monthly_charges,
		ROUND(AVG(tenure), 02) AS avg_tenure
		
	FROM billing)

SELECT total_customers, 
		total_revenue, 
		avg_monthly_charges, 
		avg_tenure, 
		churn_customers, 
		ROUND(churn_customers * 100.0 / total_customers, 2 ) AS churn_percentage
		
FROM churned_customers;

---complete customer profile easy to change
WITH customer_details AS 
	(SELECT c.customerid, c.gender, c.partner, c.dependents, s.internetservice, s.techsupport, 
		b.tenure, b.contract, b.paymentmethod, b.monthlycharges, b.totalcharges, b.churn,
		CASE 
			WHEN tenure < 12 THEN 'New Customer'
			WHEN tenure < 36 THEN 'Regular Customer'
			ELSE 'Loyal Customer'
			END AS customer_segment
	 FROM customers AS c
	 LEFT JOIN services AS s
	 ON c.customerid = s.customerid
	 LEFT JOIN billing AS b
	 ON s.customerid = b.customerid)

SELECT 
	SUM(CASE
			WHEN TRIM(LOWER(churn)) = 'yes' THEN 1 
			ELSE 0 
			END) AS churn_customers 
FROM customer_details;


