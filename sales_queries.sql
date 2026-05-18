-- Creating tables

DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS monthly_revenue;
DROP TABLE IF EXISTS product_summary;


CREATE TABLE customers (
	customer_id	TEXT,
	country	TEXT,
	age	INT,
	gender	TEXT,
	membership_tier TEXT,	
	registration_date DATE,	
	total_orders INT,	
	total_spend_usd	NUMERIC(10,2),
	avg_order_value_usd	NUMERIC(10,2),
	days_since_last_purchase INT,	
	preferred_category TEXT,	
	preferred_device TEXT, 	
	preferred_payment_method TEXT,	
	acquisition_channel TEXT,	
	reviews_given INT,	
	avg_review_score NUMERIC(10,2),	
	returns_made INT,	
	wishlist_items	INT,
	newsletter_subscribed INT,	
	churned INT
);

 
CREATE TABLE orders(
	order_id TEXT,	
	customer_id	TEXT,
	order_date DATE,	
	year INT,	
	month INT,	
	quarter	TEXT,
	day_of_week TEXT,	
	product_name TEXT,	
	category TEXT,	
	unit_price_usd NUMERIC(10,2),	
	quantity INT,	
	subtotal_usd NUMERIC(10,2),	
	discount_pct INT,	
	discount_amount_usd NUMERIC(10,2),	
	shipping_fee_usd NUMERIC(10,2), 	
	tax_pct INT, 	
	tax_amount_usd NUMERIC(10,2), 	
	total_amount_usd NUMERIC(10,2),	
	payment_method TEXT,	
	device_used	TEXT,
	delivery_days INT,	
	delivery_date DATE,	
	order_status TEXT,	
	returned INT,	
	customer_rating NUMERIC(10,2),	
	session_duration_minutes NUMERIC(10,2), 	
	pages_viewed_before_purchase INT,	
	is_repeat_customer INT
);


CREATE TABLE monthly_revenue (
	year INT,	
	month INT,	
	quarter	TEXT,
	orders INT,	
	revenue_usd NUMERIC(10,2),	
	avg_order_value	NUMERIC(10,2),
	avg_discount_pct NUMERIC(10,2),	
	unique_customers INT,	
	new_customers INT
);


CREATE TABLE product_summary (
	category TEXT,	
	product_name TEXT,	
	total_orders INT,	
	total_revenue_usd NUMERIC(10,2),	
	avg_price NUMERIC(10,2),	
	avg_rating NUMERIC(10,2),	
	return_rate	NUMERIC(10,2),
	avg_discount_pct NUMERIC(10,2),	
	avg_delivery_days NUMERIC(10,2)
);


-- ============================================================
-- PART 1: Product & Revenue Analysis
-- ============================================================


-- Top 3 products by total revenue and units sold
-- Finding: Portable Charger, Webcam, and Smart Watch are the top 3 -- all Electronics.

SELECT product_name,  SUM(total_amount_usd), SUM(quantity), category
FROM orders
GROUP BY 1,4
ORDER BY 2 DESC
LIMIT 3 ;


-- Top selling product per country using JOIN between orders and customers tables
-- Finding: Electronics consistently ranks #1 across most countries,

WITH top_country_products AS (
	SELECT o.product_name, SUM(o.total_amount_usd) total_price, c.country,
	   RANK() OVER(PARTITION BY c.country order by  SUM(o.total_amount_usd) DESC) rnk
	FROM orders o
	JOIN customers c
	ON o.customer_id = c.customer_id
	GROUP BY 1,3
)
SELECT product_name, total_price, country
FROM top_country_products
WHERE rnk =1;


-- Average revenue per year
-- Finding: Revenue increases consistently year over year.

SELECT year, ROUND(AVG(total_amount_usd), 2) avg_revenue
FROM orders
GROUP BY 1
ORDER BY 1;


-- Identifying the highest revenue quarter for each year
-- Finding: Q2 was consistently the top quarter from 2020 to 2023,
-- shifting to Q3 in 2024 and 2025. 2026 is excluded from conclusions as the year is incomplete.

WITH top_quarters AS (
	SELECT year, quarter, ROUND(AVG(total_amount_usd), 2) avg_revenue,
		RANK() OVER(PARTITION BY year ORDER BY AVG(total_amount_usd) DESC) rnk
	FROM orders
	GROUP BY 1, 2
)
SELECT year, quarter, avg_revenue
FROM top_quarters
WHERE rnk = 1
ORDER BY 1;


-- Analyzing product return rates by joining orders and product_summary
-- Note: Sorting by absolute returns (SUM) is misleading -- Electronics appears highest
-- but when sorted by return RATE (%), Travel & Luggage products have the highest return rate.
-- Key insight: Always measure returns as a percentage of sales, not absolute numbers.

SELECT o.product_name, SUM(o.returned), o.category, AVG(p.return_rate)
FROM orders o
JOIN product_summary p
ON
	o.product_name = p.product_name
GROUP BY 1,3
ORDER BY 4 DESC
LIMIT 5;


-- Analyzing average customer ratings vs product price
-- Finding: Top rated products all scored 5 stars -- likely reflects synthetic data limitations.

SELECT product_name, unit_price_usd, AVG(customer_rating)
FROM orders 
WHERE customer_rating IS NOT NULL
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 3;


-- ============================================================
-- PART 2: Customer Behavior Analysis
-- ============================================================


-- Measuring customer loyalty: comparing one-time buyers vs repeat customers

SELECT COUNT(is_repeat_customer), is_repeat_customer
FROM orders
GROUP BY 2
ORDER BY 1


-- Attempted to correlate returns with customer ratings
-- Finding: Returned orders have no customer ratings in this dataset,
-- making it impossible to determine if low ratings drove returns.
-- This represents a data collection gap worth flagging to the business.

SELECT COUNT(returned), customer_rating
FROM orders
WHERE customer_rating IS NOT NULL 
	AND returned = 1
GROUP BY 2
ORDER BY 1 DESC
LIMIT 5


-- Segmenting customers by age group to identify the dominant buying demographic
-- Finding: Middle Aged customers (35-49) represent the largest segment,
-- followed by Adults (25-34). Seniors are the smallest group.

SELECT COUNT(age),
	CASE
		WHEN age BETWEEN 18 and 24 THEN 'Young Adult'
		WHEN age BETWEEN 25 and 34 THEN 'Adult'
		WHEN age BETWEEN 35 and 49 THEN 'Middle Aged'
		ELSE 'Senior'
	END
FROM customers
GROUP BY 2;


-- Analyzing whether newsletter subscription correlates with higher order frequency
-- Finding: Non-subscribers (avg 16.9 orders) slightly outperform subscribers (avg 16.3 orders),
-- suggesting newsletters have no significant impact on purchase frequency in this dataset.

SELECT 
	newsletter_subscribed , AVG(total_orders) avg_orders
FROM customers
GROUP BY 1
ORDER BY 2 DESC;


-- Identifying the month with the highest new customer acquisition and its discount rate
-- Finding: December 2021 had the highest new customers (122),
-- with a discount rate of 4.93% -- close to average.
-- Suggests holiday season demand, not discounts, drove new customer growth.

WITH high_month AS (
	SELECT month, year, SUM(new_customers)sum_new_customers, avg_discount_pct,
		RANK() OVER(ORDER BY SUM(new_customers) DESC) rnk_months
	FROM monthly_revenue
	GROUP BY 1,2,4

)
SELECT month, year, sum_new_customers, avg_discount_pct
FROM high_month
WHERE rnk_months =1;


-- Comparing average spending between male and female customers
-- Finding: Males spend slightly more on average ($1,574) vs females ($1,539),
-- but the difference is minimal, suggesting gender has little impact on spending behavior.

SELECT gender, avg(total_spend_usd)
FROM customers
GROUP BY 1
ORDER BY 2
LIMIT 2;


-- Finding the highest spending customer within each membership tier
-- Finding: Platinum tier leads as expected, but Free tier surprisingly outspends
-- Gold and Silver -- suggesting high-value customers who haven't upgraded their membership yet.
-- These Free tier customers are strong candidates for membership upgrade campaigns.

WITH top_customers AS (
	SELECT customer_id, membership_tier, AVG(total_spend_usd) avg_spend,
		RANK() OVER(PARTITION BY membership_tier ORDER BY AVG(total_spend_usd) DESC) rnk_tiers		   
	FROM customers
	GROUP BY 1,2
)
SELECT customer_id, membership_tier, avg_spend
FROM top_customers
WHERE rnk_tiers =1;


-- Analyzing churn rate by membership tier
-- Finding: Gold tier has the highest churn rate (9%), followed by Free, Platinum, and Silver.
-- Key insight: Gold members churning at a higher rate than Platinum suggests
-- the Gold tier may not be delivering sufficient value to justify retention.

SELECT membership_tier, AVG(churned)
FROM customers
GROUP BY 1
ORDER BY 2 DESC;


-- Analyzing churn rate by acquisition channel
-- Finding: Referral channel has the highest churn rate, which is counterintuitive
-- as referred customers are typically considered high quality leads.

SELECT acquisition_channel, AVG(churned)
FROM customers
GROUP BY 1
ORDER BY 2 DESC;


-- Analyzing churn rate by age group using CASE WHEN segmentation
-- Finding: Young Adults (18-24) have the highest churn rate

SELECT AVG(churned),
	CASE
		WHEN age BETWEEN 18 and 24 THEN 'Young Adult'
		WHEN age BETWEEN 25 and 34 THEN 'Adult'
		WHEN age BETWEEN 35 and 49 THEN 'Middle Aged'
		ELSE 'Senior'
	END
FROM customers
GROUP BY 2
ORDER BY 1;