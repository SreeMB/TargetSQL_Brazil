Import the dataset and do the usual exploratory analysis steps like 
checking the structure & characteristics of the dataset 
# 1.1 Getting the data types of all the tables
SELECT COLUMN_NAME, DATA_TYPE
FROM targetsql.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customers';

SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM targetsql.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'orders';

SELECT COLUMN_NAME, DATA_TYPE
FROM targetsql.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'geolocation';

SELECT COLUMN_NAME, DATA_TYPE
FROM targetsql.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'order_items';

SELECT COLUMN_NAME, DATA_TYPE
FROM targetsql.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'order_reviews';

SELECT COLUMN_NAME, DATA_TYPE
FROM targetsql.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'payments';

SELECT COLUMN_NAME, DATA_TYPE
FROM targetsql.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'products';

SELECT COLUMN_NAME, DATA_TYPE
FROM targetsql.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sellers';

SELECT 
       TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM 
       targetsql.INFORMATION_SCHEMA.COLUMNS;


# 1.2 Get the time range between which the orders were placed.
SELECT MIN(order_purchase_timestamp) AS start_date,
       MAX(order_purchase_timestamp) AS end_date, 
       DATE_DIFF(MAX(order_purchase_timestamp), MIN(order_purchase_timestamp), DAY) AS time_range
FROM `targetsql.orders`;


#1.3 Count the Cities & States of customers who ordered during the given period.
-- Getting list of all cities and countries of customers who placed order during the period of 772 days.
SELECT 
       distinct c.customer_city, c.customer_state
FROM 
       `targetsql.customers` c 
JOIN `targetsql.orders` o ON c.customer_id = o.customer_id
order by 
       c.customer_state;

--Getting the count of cities and countried
SELECT count(distinct c.customer_city) as city_count, 
       count(distinct c.customer_state) as state_count
FROM 
       `targetsql.customers` c 
JOIN 
       `targetsql.orders` o ON c.customer_id = o.customer_id;

--INDEPT EXPLORATION
#2.1 Is there a growing trend in the no. of orders placed over the past years?



SELECT 
       EXTRACT(YEAR FROM order_purchase_timestamp) as years, 
       EXTRACT(MONTH FROM order_purchase_timestamp) as months, 
       order_purchase_timestamp
FROM 
       `targetsql.orders`
WHERE
       lower(order_status) = 'delivered';

SELECT 
       EXTRACT(YEAR FROM order_purchase_timestamp) as years, 
       EXTRACT(MONTH FROM order_purchase_timestamp) as months, 
       count(*) as num_of_orders
FROM 
       `targetsql.orders`
WHERE
       lower(order_status) = 'delivered'
GROUP BY 
       1,2
ORDER BY 
       1,2;

#2.2 Can we see some kind of monthly seasonality in terms of the no. of orders being placed?
--For orders the orders that are sucessfully delivered
SELECT EXTRACT(YEAR FROM order_purchase_timestamp) as years, 
       EXTRACT(MONTH FROM order_purchase_timestamp) as months, 
       count(*) as num_orders
FROM 
       `targetsql.orders`
WHERE
       lower(order_status) = 'delivered'
GROUP BY  
       1,2
ORDER BY 
       3 DESC;


#2.3 During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
-- 0-6 hrs : Dawn
-- 7-12 hrs : Mornings
-- 13-18 hrs : Afternoon
-- 19-23 hrs : Night
--Adding a new column that gives info about the part of the day
select order_id, order_purchase_timestamp, time(order_purchase_timestamp) as order_time,
       CASE
       WHEN time(order_purchase_timestamp) between '00:00:00' and '06:59:59' then 'Dawn'
       WHEN time(order_purchase_timestamp) between '07:00:00' and '12:59:59' then 'Mornings'
       WHEN time(order_purchase_timestamp) between '13:00:00' and '18:59:59' then 'Afternoon'
       WHEN time(order_purchase_timestamp) between '19:00:00' and '23:59:59' then 'Night'
       end as time_of_day
from 
       `targetsql.orders`
order by 
       order_purchase_timestamp;

--count of orders during the part of the day
WITH orders_time_day as (select order_id, order_purchase_timestamp, time(order_purchase_timestamp) as order_time,
       CASE
       WHEN time(order_purchase_timestamp) between '00:00:00' and '06:59:59' then 'Dawn'
       WHEN time(order_purchase_timestamp) between '07:00:00' and '12:59:59' then 'Mornings'
       WHEN time(order_purchase_timestamp) between '13:00:00' and '18:59:59' then 'Afternoon'
       WHEN time(order_purchase_timestamp) between '19:00:00' and '23:59:59' then 'Night'
       end as time_of_day
from 
       `targetsql.orders`
order by 
       order_purchase_timestamp)

SELECT o.time_of_day,
       COUNT(*) as num_orders_prt_day
FROM 
       orders_time_day o
GROUP BY 
       o.time_of_day
ORDER BY 
       num_orders_prt_day DESC;
# 3. Evolution of E-commerce orders in the Brazil region:
#3.1 Get the month on month no. of orders placed in each state.
--Getting the orders placed by each city and state
SELECT 
       c.customer_state, t.years, t.months, count(*) as orders_per_state
FROM 
       `targetsql.customers` c 
JOIN (SELECT EXTRACT(YEAR FROM order_purchase_timestamp) as years, 
              EXTRACT(MONTH FROM order_purchase_timestamp) as months, 
              customer_id
       FROM `targetsql.orders`) t 
ON 
       c.customer_id = t.customer_id
GROUP BY 
       c.customer_state, t.years, t.months
order by 
       t.years, t.months;

--comaprision based on each state
SELECT 
       c.customer_state, t.months, 
       count(*) as orders_per_state
FROM  
       `targetsql.customers` c 
JOIN (
       SELECT EXTRACT(YEAR FROM order_purchase_timestamp) as years, 
              EXTRACT(MONTH FROM order_purchase_timestamp) as months, 
              customer_id
              FROM `targetsql.orders`) t 
ON 
       c.customer_id = t.customer_id
GROUP BY 
       c.customer_state, t.months
order by 
       3 DESC;

-- Comparision with orders of next month for each state
WITH month_wise as (
SELECT c.customer_state as state, t.years as years, t.months as months, count(*) as orders_per_state
       FROM `targetsql.customers` c JOIN (SELECT EXTRACT(YEAR FROM order_purchase_timestamp) as years, 
                                          EXTRACT(MONTH FROM order_purchase_timestamp) as months, 
                                          customer_id
                                 FROM `targetsql.orders`) t 
ON c.customer_id = t.customer_id
GROUP BY c.customer_state, t.years, t.months
)

select pm.state as state, pm.years as year, pm.months as present_month, pm.orders_per_state as present_month_orders,
       nm.years as year, nm.months as next_month, nm.orders_per_state as next_month_orders
from month_wise pm join month_wise nm
on pm.state = nm.state
where pm.years = nm.years and nm.months = pm.months+1
order by pm.state, pm.years, pm.months;

--Calculating the %difference btw consecutive orders for each state
WITH month_wise as (
SELECT
       c.customer_state as state, t.years as years, t.months as months, count(*) as orders_per_state
FROM 
       `targetsql.customers` c 
JOIN 
       (SELECT 
              EXTRACT(YEAR FROM order_purchase_timestamp) as years, 
              EXTRACT(MONTH FROM order_purchase_timestamp) as months, 
              customer_id
       FROM 
              `targetsql.orders`) t ON c.customer_id = t.customer_id
GROUP BY 
       c.customer_state, t.years, t.months
)
SELECT 
       *, 
       ROUND((nm.orders_per_state -pm.orders_per_state)/pm.orders_per_state * 100, 2) as prec_diff
FROM 
       month_wise pm 
JOIN 
       month_wise nm on pm.state = nm.state
WHERE 
       pm.years = nm.years and nm.months = pm.months+1
ORDER BY 
       pm.state, pm.years, pm.months;



--Month on month orders vs the revenue it generated for each state
SELECT 
       c.customer_state, t.years, t.months, 
       count(*) as orders_per_state,
       ROUND(SUM(p.payment_value),3) as total_revenue_per_month
FROM  
       `targetsql.customers` c 
JOIN (
       SELECT EXTRACT(YEAR FROM order_purchase_timestamp) as years, 
              EXTRACT(MONTH FROM order_purchase_timestamp) as months, 
              customer_id, order_id
              FROM `targetsql.orders`) t ON c.customer_id = t.customer_id
JOIN 
       `targetsql.payments` p ON p.order_id = t.order_id 
GROUP BY 
       c.customer_state, t.years, t.months
order by 
       3 DESC, 4 DESC;



SELECT EXTRACT(YEAR FROM order_purchase_timestamp) as years,
       EXTRACT(MONTH FROM order_purchase_timestamp) as months,
       COUNT(o.order_id) as num_orders,
       ROUND(SUM(p.payment_value),3) as total_revenue_per_month
FROM 
       `targetsql.orders` o  
JOIN  `targetsql.payments` p ON o.order_id = p.order_id
GROUP BY 
       1,2
ORDER BY 
       1,2;




#3.2 How are the customers distributed across all the states?
SELECT *
FROM `targetsql.customers` c full outer join `targetsql.orders` o  
on c.customer_id = o.customer_id
where o.order_id is null or c.customer_id is null;


--this shows us that there are no customers that haven't placed any orders also there are no orders placed by guest customers/ without customer info
select customer_state, customer_city, count(*) as no_of_cust
from `targetsql.customers`
group by customer_city, customer_state
order by 1,2;


select c.customer_id, customer_city, c.customer_state, c.customer_zip_code_prefix, g.geolocation_zip_code_prefix, g.geolocation_city,g.geolocation_state
from `targetsql.geolocation` g join `targetsql.customers` c
ON g.geolocation_zip_code_prefix = c.customer_zip_code_prefix;
--there is no new information in geolocations table


#4. Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.

# 4.1 Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only). You can use the "payment_value" column in the payments table to get the cost of orders.

--Creating a temporary table of orders displaying years and months of the orders
WITH orders_YM as (SELECT order_id, 
       EXTRACT(YEAR FROM order_purchase_timestamp) as years,
       EXTRACT(MONTH FROM order_purchase_timestamp) as months,
       FORMAT_DATETIME("%Y - %m",order_purchase_timestamp) as year_month,
       order_status  
FROM `targetsql.orders`)


--Getting the orders between 2017 -2018 of months from Jan to August only
SELECT *
FROM (SELECT order_id, 
       EXTRACT(YEAR FROM order_purchase_timestamp) as years,
       EXTRACT(MONTH FROM order_purchase_timestamp) as months  
       FROM `targetsql.orders`) tbl
WHERE (tbl.years = 2017 or tbl.years = 2018)
      AND tbl.months between 01 and 08 
ORDER BY tbl.years, tbl.months DESC;

--Getting the cost of orders wrt year, month.
WITH orders_YM as (SELECT order_id, 
       EXTRACT(YEAR FROM order_purchase_timestamp) as years,
       EXTRACT(MONTH FROM order_purchase_timestamp) as months,
       order_status  
FROM `targetsql.orders`)

SELECT o.years,
       ROUND(SUM(payment_value),3) as cost_of_orders_mnthwise
FROM orders_YM o join `targetsql.payments` p  
ON o.order_id = p.order_id
GROUP BY o.years
ORDER BY o.years;

--Displaying the descending order of cost of orders 
WITH orders_YM as (SELECT order_id, 
                          FORMAT_DATETIME("%Y - %m",order_purchase_timestamp) as year_month,
                          order_purchase_timestamp
                   FROM `targetsql.orders`)

SELECT FORMAT_DATETIME("%Y - %m", o.order_purchase_timestamp) as year_month, 
       ROUND(SUM(payment_value),3) as cost_of_orders_mnthwise
FROM orders_YM o join `targetsql.payments` p  
ON o.order_id = p.order_id
GROUP BY FORMAT_DATETIME("%Y - %m", o.order_purchase_timestamp)
ORDER BY cost_of_orders_mnthwise DESC;

-- The cost of orders from year 2017 to 2018 (include months between Jan to Aug only)
WITH orders_YM as (SELECT order_id, 
                          EXTRACT(YEAR FROM order_purchase_timestamp) as years,
                          EXTRACT(MONTH FROM order_purchase_timestamp) as months,
                          FORMAT_DATETIME("%Y - %m", order_purchase_timestamp) as year_month,
                          order_purchase_timestamp
                   FROM `targetsql.orders`)


SELECT o.year_month, 
       ROUND(SUM(payment_value),3) as cost_of_orders_mnthwise
FROM orders_YM o JOIN `targetsql.payments` p  
ON o.order_id = p.order_id
WHERE (o.years = 2017 or o.years = 2018)
      AND o.months between 01 and 09
GROUP BY o.year_month
ORDER BY o.year_month;


--% of increase in cost of orders month-wise from 2017 to 2018

WITH orders_YM as (SELECT 
                          order_id, 
                          EXTRACT(YEAR FROM order_purchase_timestamp) as years,
                          EXTRACT(MONTH FROM order_purchase_timestamp) as months,
                          FORMAT_DATETIME("%Y - %m", order_purchase_timestamp) as year_month,
                          order_purchase_timestamp
                   FROM 
                     `targetsql.orders`),
cost_of_order_1718 as (SELECT 
                            o.years as YEAR, o.months as MONTH,
                            ROUND(SUM(payment_value),3) as cost_of_orders_mnthwise
                       FROM 
                            orders_YM o 
                       JOIN 
                            `targetsql.payments` p  ON o.order_id = p.order_id
                       WHERE 
                            (o.years = 2017 or o.years = 2018)
                            AND o.months between 01 and 08
                       GROUP BY   
                            o.years, o.months 
                       ORDER BY 
                            o.years, o.months )

SELECT 
       p.YEAR, p.MONTH, p.cost_of_orders_mnthwise, n.YEAR as NXT_YR, n.MONTH as NXT_MNTH, n.cost_of_orders_mnthwise,
       ROUND((n.cost_of_orders_mnthwise - p.cost_of_orders_mnthwise)/p.cost_of_orders_mnthwise * 100,2) as `%increase_monthwise`
FROM 
       cost_of_order_1718 p  
JOIN 
       cost_of_order_1718 n   ON  p.YEAR = 2017 and n.YEAR = 2018 and n.MONTH = p.MONTH
ORDER BY 2;

--% of increase in cost of orders year-wise from 2017 to 2018
WITH orders_YM as 
       (SELECT 
              order_id, 
              EXTRACT(YEAR FROM order_purchase_timestamp) as years,
              EXTRACT(MONTH FROM order_purchase_timestamp) as months,
              FORMAT_DATETIME("%Y - %m", order_purchase_timestamp) as year_month,
              order_purchase_timestamp
       FROM 
              `targetsql.orders`)

SELECT 
       o.years as YEAR,
       ROUND(SUM(payment_value),3) as cost_of_orders,
       CASE
              WHEN o.years = 2017 THEN 0
              ELSE ROUND((SUM(CASE WHEN o.years = 2018 THEN p.payment_value ELSE 0 END)- LAG(ROUND(SUM(payment_value),3)) over(order by o.years))/ LAG(ROUND(SUM(payment_value),3)) over(order by o.years) *100, 2)
       END as nxt_yr_cost
      
FROM 
       orders_YM o 
JOIN 
       `targetsql.payments` p  ON o.order_id = p.order_id
WHERE 
       (o.years = 2017 or o.years = 2018)
       AND o.months between 01 and 08
GROUP BY   
       o.years
ORDER BY 
       o.years;


#4.2 Calculate the Total & Average value of order price for each state.

--Creating a temporary table displaying orders wrt each state and city
SELECT
       c.customer_state, c.customer_city,
       ROUND(SUM(p.payment_value), 2) as total_price_city,
       ROUND(AVG(p.payment_value),2) as avg_price_city
FROM 
       `targetsql.customers` c
JOIN 
       `targetsql.orders` o ON c.customer_id = o.customer_id
JOIN
       `targetsql.payments` p ON o.order_id = p.order_id
GROUP BY 
       c.customer_state, c.customer_city
ORDER BY
       total_price_city desc, avg_price_city;

--Statewise
SELECT
       c.customer_state,
       ROUND(SUM(p.payment_value), 2) as total_price,
       ROUND(AVG(p.payment_value),2) as avg_price
FROM 
       `targetsql.customers` c
JOIN 
       `targetsql.orders` o ON c.customer_id = o.customer_id
JOIN
       `targetsql.payments` p ON o.order_id = p.order_id
GROUP BY 
       c.customer_state
ORDER BY
       total_price desc, avg_price;


#4.3 Calculate the Total & Average value of order freight for each state.
--Displaying the Total & Average value of order freight for each state and city
SELECT
       c.customer_state, customer_city,
       ROUND(SUM(oi.freight_value),2) as total_freight_city,
       ROUND(AVG(oi.freight_value),2) as avg_freight_city
FROM
       `targetsql.customers` c  
JOIN 
       `targetsql.orders` o ON c.customer_id = o.customer_id
JOIN 
       `targetsql.order_items` oi ON o.order_id = oi.order_id
GROUP BY 
       c.customer_state, customer_city
ORDER BY 
       total_freight_city desc, avg_freight_city;
--Statewise
SELECT
       c.customer_state,
       ROUND(SUM(oi.freight_value),2) as total_freight,
       ROUND(AVG(oi.freight_value),2) as avg_freight
FROM
       `targetsql.customers` c  
JOIN 
       `targetsql.orders` o ON c.customer_id = o.customer_id
JOIN 
       `targetsql.order_items` oi ON o.order_id = oi.order_id
GROUP BY 
       c.customer_state
ORDER BY 
       total_freight desc, avg_freight;

#5.	Analysis based on sales, freight and delivery time.
#5.11.	Find the no. of days taken to deliver each order from the order’s purchase date as delivery time. Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
-- checking for NUll in order date
SELECT
  *
FROM
  `targetsql.orders`
WHERE
  order_purchase_timestamp is NUll;

SELECT 
  order_id,
  order_purchase_timestamp,
  DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_purchase_timestamp), DAY) as act_time_delivery,
  DATE_DIFF(DATE(order_estimated_delivery_date), DATE(order_purchase_timestamp), DAY) as est_time_delivery,
  DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_estimated_delivery_date), DAY) as diff_delivery

FROM
  `targetsql.orders`
WHERE
  lower(order_status) = 'delivered' and order_delivered_customer_date is not NULL
ORDER BY 
  3 DESC;

#5.2.	Find out the top 5 states with the highest & lowest average freight value.
WITH avg_fr_val as 
(SELECT
  c.customer_id, c.customer_city, c.customer_state, oi.freight_value as freight_value,
  MIN(freight_value) over(partition by customer_state) as lowest_freight_value,
  MAX(freight_value) over(partition by customer_state) as highest_freight_value,
  ROUND(AVG(freight_value) over(partition by customer_state), 2) as avg_freight_value,
  
FROM
  `targetsql.customers` c
JOIN
  `targetsql.orders` o ON c.customer_id = o.customer_id
JOIN 
  `targetsql.order_items` oi ON o.order_id = oi.order_id
WHERE
  lower(order_status) = 'delivered'
)
 -- TOP 5 states
SELECT
  c.customer_state, a.avg_freight_value
  
FROM
  `targetsql.customers` c
JOIN
  avg_fr_val a ON c.customer_id = a.customer_id
GROUP BY 
  c.customer_state, a.avg_freight_value
ORDER BY 
  a.avg_freight_value desc
LIMIT 5;

--LOWEST 5 states
WITH avg_fr_val as 
(SELECT
  c.customer_id, c.customer_city, c.customer_state, oi.freight_value as freight_value,
  MIN(freight_value) over(partition by customer_state) as lowest_freight_value,
  MAX(freight_value) over(partition by customer_state) as highest_freight_value,
  ROUND(AVG(freight_value) over(partition by customer_state), 2) as avg_freight_value,
  
FROM
  `targetsql.customers` c
JOIN
  `targetsql.orders` o ON c.customer_id = o.customer_id
JOIN 
  `targetsql.order_items` oi ON o.order_id = oi.order_id
WHERE
  lower(order_status) = 'delivered'
)
SELECT
  c.customer_state, a.avg_freight_value
  
FROM
  `targetsql.customers` c
JOIN
  avg_fr_val a ON c.customer_id = a.customer_id
GROUP BY 
  c.customer_state, a.avg_freight_value
ORDER BY 
  a.avg_freight_value
LIMIT 5;

#5.3 3.	Find out the top 5 states with the highest & lowest average delivery time.
WITH delivery_time as
(
SELECT 
  order_id, customer_id,
  order_purchase_timestamp,
  DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_purchase_timestamp), DAY) as act_time_delivery,
  DATE_DIFF(DATE(order_estimated_delivery_date), DATE(order_purchase_timestamp), DAY) as est_time_delivery,
  DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_estimated_delivery_date), DAY) as diff_delivery

FROM
  `targetsql.orders`
WHERE
  lower(order_status) = 'delivered')
--TOP 5
SELECT 
  c.customer_state, ROUND(AVG(d.act_time_delivery), 2) as avg_delivery_time
FROM
 `targetsql.customers` c
JOIN 
  delivery_time as d ON c.customer_id = d.customer_id
GROUP BY 
  c.customer_state
ORDER BY
  avg(d.act_time_delivery) DESC
LIMIT 5;

--Bottom 5

WITH delivery_time as
(
SELECT 
  order_id, customer_id,
  order_purchase_timestamp,
  DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_purchase_timestamp), DAY) as act_time_delivery,
  DATE_DIFF(DATE(order_estimated_delivery_date), DATE(order_purchase_timestamp), DAY) as est_time_delivery,
  DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_estimated_delivery_date), DAY) as diff_delivery

FROM
  `targetsql.orders`
WHERE
  lower(order_status) = 'delivered')

SELECT 
  c.customer_state, ROUND(AVG(d.act_time_delivery), 2) as avg_delivery_time
FROM
 `targetsql.customers` c
JOIN 
  delivery_time as d ON c.customer_id = d.customer_id
GROUP BY 
  c.customer_state
ORDER BY
  avg(d.act_time_delivery) 
LIMIT 5;

#5.4.	Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.

WITH delivery_time as
(
SELECT 
  order_id, customer_id,
  order_purchase_timestamp,
  DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_purchase_timestamp), DAY) as act_time_delivery,
  DATE_DIFF(DATE(order_estimated_delivery_date), DATE(order_purchase_timestamp), DAY) as est_time_delivery,
  DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_estimated_delivery_date), DAY) as diff_delivery

FROM
  `targetsql.orders`
WHERE
  lower(order_status) = 'delivered' and order_delivered_customer_date is not NULL)


SELECT
  c.customer_state, 
  ROUND(AVG(d.diff_delivery), 2) as avg_diff_delivery
FROM
 `targetsql.customers` c
JOIN 
  delivery_time d ON c.customer_id = d.customer_id
GROUP BY 
  c.customer_state
ORDER BY 
  AVG(d.diff_delivery) 
LIMIT 5




# 6.Analysis based on the payments:
#6.1 1.	Find the month on month no. of orders placed using different payment types.

--Creating a temporary table by adding the years and months col to the og table
WITH orders_YM as (SELECT order_id, customer_id,
       EXTRACT(YEAR FROM order_purchase_timestamp) as years,
       EXTRACT(MONTH FROM order_purchase_timestamp) as months,
       FORMAT_DATETIME("%Y - %m",order_purchase_timestamp) as year_month,
       order_status  
FROM `targetsql.orders`
WHERE 
  lower(order_status) = 'delivered'),

--Temporary table for types of payments per order_id
payment_type_order as
(SELECT
  order_id, payment_type, COUNT(*) num_trans_per_paytype
FROM
 `targetsql.payments` p  
GROUP BY 
  payment_type, order_id
)

SELECT
  o.years, o.months, p.payment_type,
  COUNT(p.num_trans_per_paytype)
FROM
  `targetsql.customers` c
JOIN
 orders_YM o ON c.customer_id = o.customer_id
JOIN 
  payment_type_order p ON o.order_id = p.order_id
GROUP BY 
  o.years, o.months, p.payment_type
ORDER BY 
  p.payment_type;


#6.2 	Find the no. of orders placed on the basis of the payment installments that have been paid.
--Intial check to know how many orders are there per installment
SELECT 
  payment_installments, COUNT(*) AS num_order_inst

FROM
  `targetsql.payments`
GROUP BY 
  payment_installments
ORDER BY 
  payment_installments
LIMIT 50;

--The orders based on the basis of installments
SELECT
  p.payment_installments,
  COUNT(o.order_id) as num_orders_inst
FROM
 `targetsql.orders` o  
JOIN 
  `targetsql.payments` p ON o.order_id = p.order_id
WHERE 
  lower(o.order_status) != 'cancelled'
GROUP BY
  p.payment_installments
ORDER BY
  2 DESC

















