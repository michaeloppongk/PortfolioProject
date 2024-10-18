--Create a list of distinct districts customers are from
SELECT  DISTINCT(district)
FROM address;

-- What is the latest rental date ?
SELECT *
FROM rental
ORDER BY rental_date DESC
LIMIT(1);

-- How many films does the company have ?
SELECT COUNT(film_id)
FROM film;

-- How many distinct last names of the customers are there ?
SELECT COUNT(DISTINCT(last_name))
FROM customer;

-- How many movies are there that contain 'Saga' in Description and where title starts either with 'A' or ends with 'R'
SELECT COUNT(*) AS no_of_movies
FROM film
WHERE description LIKE '%Saga%' 
AND (title LIKE 'A%' OR title LIKE '%R');

-- Create a list of all customers where the first name contains 'ER' and has 'A' as the second letter
SELECT *
FROM customer
WHERE first_name LIKE '%ER%'
AND first_name LIKE '_A%'
ORDER BY last_name DESC;

-- How many payments are there where the amount is either 0 or is between 3.99 and 7.99 and in the same time happened on 2020-05-01
SELECT COUNT(*)
FROM payment
WHERE (amount = 0 
OR amount BETWEEN 3.99 AND 7.99)
AND payment_date BETWEEN '2020-05-01' AND '2020-05-02';

-- What are the Minimum, Maximum, Average(rounded), Sum of the replacement costs of films
SELECT MIN(replacement_cost),
MAX(replacement_cost),
ROUND (AVG(replacement_cost),2) AS avg_replacement_cost,
SUM(replacement_cost)
FROM film;

-- Which of the employees is responsible for more payments ?
SELECT staff_id,
COUNT(amount)
FROM payment
GROUP BY staff_id
ORDER BY COUNT(amount) DESC;

-- Which of the employees is responsible for a higher overall payment amount ?
SELECT staff_id,
SUM(amount)
FROM payment
GROUP BY staff_id
ORDER BY SUM(amount) DESC;

-- Which employee had the highest sales in a single day(not counting payments with amount =0) ?
SELECT staff_id,
DATE(payment_date),
SUM(amount),
COUNT(*)
FROM payment
WHERE amount !=0
GROUP BY staff_id, DATE(payment_date) 
ORDER BY SUM(amount) DESC;

-- Find out what is the average payment amount grouped by customer and day. Consider only the days/customers with more than 1 payment
SELECT customer_id,
DATE(payment_date),
ROUND(AVG(amount),2) AS avg_amount,
COUNT(*)
FROM payment
WHERE DATE(payment_date) BETWEEN '2020-04-28' AND '2020-04-30'
GROUP BY customer_id, DATE(payment_date)
HAVING COUNT(*) > 1
ORDER BY avg_amount DESC;

-- What are the customers with their details based in the district of Texas
SELECT cu.address_id,
address,
ad.district,
first_name,
last_name,
phone
FROM address ad
RIGHT JOIN customer cu
ON ad.address_id = cu.address_id
WHERE district = 'Texas';

-- Are they any (old) addresses that are not related to any customer ?
SELECT *
FROM address ad
LEFT JOIN customer cu
ON cu.address_id = ad.address_id
WHERE cu.customer_id IS NULL;

-- Get contact details of customers from Brazil
SELECT first_name,
last_name,
email,
ct.country,
district,
ad.address
FROM country ct
LEFT JOIN city cy 
ON ct.country_id = cy.country_id
LEFT JOIN address ad
ON cy.city_id = ad.city_id
LEFT JOIN customer cu
ON cu.address_id = ad.address_id
WHERE country = 'Brazil';

-- Combine all names from actor, customer and staff database
SELECT first_name, last_name ,'actor'AS origin FROM  actor
UNION 
SELECT first_name, last_name, 'customer' FROM customer
UNION 
SELECT UPPER(first_name), last_name, 'staff' FROM staff
ORDER BY origin DESC;

-- Subqueries to get all data and the average amounts from the payments table 
SELECT *
FROM payment
WHERE amount > (SELECT AVG(amount) FROM payment);

-- Subquery to get multiple data from two tables
SELECT *
FROM payment
WHERE customer_id IN (SELECT customer_id FROM customer
                    WHERE first_name LIKE 'A%');

-- Subquery combining films and inventory
SELECT * FROM film
WHERE film_id IN
(SELECT film_id FROM inventory
WHERE store_id = 2
GROUP BY film_id
HAVING COUNT(*) > 3);

SELECT first_name, last_name
FROM customer
WHERE customer_id IN (SELECT customer_id
                      FROM payment
					  WHERE DATE(payment_date)= '2020-01-25' );

--Subquery combining multiple tables
SELECT first_name, email
FROM customer
WHERE customer_id IN (SELECT customer_id
                      FROM payment
					  GROUP BY customer_id
					  HAVING SUM(amount) >100)
AND customer_id IN  (SELECT customer_id
                     FROM customer
					 INNER JOIN address
					 ON address.address_id = customer.address_id
					 WHERE district = 'California');

SELECT ROUND(AVG(total_amount),2) AS avg_lifetime_spent
FROM
(SELECT customer_id, SUM(amount) AS total_amount FROM payment
GROUP BY customer_id);

SELECT
ROUND(AVG(amount_per_day),2) AS daily_rev_avg
FROM
(SELECT 
SUM(amount) AS amount_per_day,
DATE(payment_date)
FROM payment
GROUP BY DATE(payment_date)) A;

SELECT *,
(SELECT ROUND(AVG(amount),2) FROM payment)
FROM payment;

SELECT 
*, (SELECT MAX(amount)FROM payment)-amount AS difference FROM payment;

SELECT * FROM payment p1
WHERE amount = (SELECT MAX(amount) FROM payment p2
                WHERE p1.customer_id = p2.customer_id)
ORDER BY customer_id;

SELECT title, film_id, replacement_cost, rating
FROM film f1
WHERE replacement_cost = 
     (SELECT MIN(replacement_cost) FROM film f2
	 WHERE f1.rating =f2.rating)






