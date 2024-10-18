-- ===============================================
-- Movie Company Database Analysis
-- This script explores various metrics related to customers, films, payments, and employees
-- using advanced SQL techniques such as joins, subqueries, aggregates, and filtering.
-- Data source: Movie company database
-- ===============================================

-- 1. Create a list of distinct districts where customers are located
SELECT DISTINCT district
FROM address
ORDER BY district;

-- 2. What is the latest rental date?
SELECT rental_date
FROM rental
ORDER BY rental_date DESC
LIMIT 1;

-- 3. Count the total number of films in the database
SELECT COUNT(film_id) AS total_films
FROM film;

-- 4. Count the distinct last names of customers
SELECT COUNT(DISTINCT last_name) AS distinct_last_names
FROM customer;

-- 5. Count movies with 'Saga' in the description and title starting with 'A' or ending with 'R'
SELECT COUNT(*) AS no_of_movies
FROM film
WHERE description LIKE '%Saga%'
AND (title LIKE 'A%' OR title LIKE '%R');

-- 6. List all customers where the first name contains 'ER' and has 'A' as the second letter
SELECT *
FROM customer
WHERE first_name LIKE '%ER%'
AND first_name LIKE '_A%'
ORDER BY last_name DESC;

-- 7. Count payments with amount either 0 or between 3.99 and 7.99 on May 1, 2020
SELECT COUNT(*) AS payment_count
FROM payment
WHERE (amount = 0 OR amount BETWEEN 3.99 AND 7.99)
AND payment_date BETWEEN '2020-05-01' AND '2020-05-02';

-- 8. Calculate the Minimum, Maximum, Average, and Sum of replacement costs of films
SELECT 
    MIN(replacement_cost) AS min_replacement_cost,
    MAX(replacement_cost) AS max_replacement_cost,
    ROUND(AVG(replacement_cost), 2) AS avg_replacement_cost,
    SUM(replacement_cost) AS total_replacement_cost
FROM film;

-- 9. Identify which employee is responsible for the most payments
SELECT 
    staff_id,
    COUNT(amount) AS total_payments
FROM payment
GROUP BY staff_id
ORDER BY total_payments DESC;

-- 10. Identify which employee is responsible for the highest overall payment amount
SELECT 
    staff_id,
    SUM(amount) AS total_payment_amount
FROM payment
GROUP BY staff_id
ORDER BY total_payment_amount DESC;

-- 11. Identify the employee with the highest sales in a single day (excluding zero payments)
SELECT 
    staff_id,
    DATE(payment_date) AS sale_date,
    SUM(amount) AS total_sales,
    COUNT(*) AS total_transactions
FROM payment
WHERE amount != 0
GROUP BY staff_id, DATE(payment_date)
ORDER BY total_sales DESC
LIMIT 1;

-- 12. Find the average payment amount grouped by customer and day (only for days/customers with > 1 payment)
SELECT 
    customer_id,
    DATE(payment_date) AS payment_date,
    ROUND(AVG(amount), 2) AS avg_payment_amount,
    COUNT(*) AS payment_count
FROM payment
WHERE DATE(payment_date) BETWEEN '2020-04-28' AND '2020-04-30'
GROUP BY customer_id, DATE(payment_date)
HAVING COUNT(*) > 1
ORDER BY avg_payment_amount DESC;

-- 13. Get customer details based in the district of Texas
SELECT 
    cu.address_id,
    ad.address,
    ad.district,
    cu.first_name,
    cu.last_name,
    cu.phone
FROM address ad
RIGHT JOIN customer cu ON ad.address_id = cu.address_id
WHERE ad.district = 'Texas';

-- 14. Identify any (old) addresses that are not associated with any customers
SELECT *
FROM address ad
LEFT JOIN customer cu ON cu.address_id = ad.address_id
WHERE cu.customer_id IS NULL;

-- 15. Get contact details of customers from Brazil
SELECT 
    cu.first_name,
    cu.last_name,
    cu.email,
    ct.country,
    ad.district,
    ad.address
FROM country ct
LEFT JOIN city cy ON ct.country_id = cy.country_id
LEFT JOIN address ad ON cy.city_id = ad.city_id
LEFT JOIN customer cu ON cu.address_id = ad.address_id
WHERE ct.country = 'Brazil';

-- 16. Combine all names from actor, customer, and staff tables
SELECT 
    first_name, 
    last_name, 
    'actor' AS origin 
FROM actor
UNION 
SELECT first_name, last_name, 'customer' FROM customer
UNION 
SELECT UPPER(first_name), last_name, 'staff' FROM staff
ORDER BY origin DESC;

-- 17. Subquery to get all payments greater than the average payment amount
SELECT *
FROM payment
WHERE amount > (SELECT AVG(amount) FROM payment);

-- 18. Subquery to get payments made by customers whose first names start with 'A'
SELECT *
FROM payment
WHERE customer_id IN (SELECT customer_id FROM customer WHERE first_name LIKE 'A%');

-- 19. Subquery to find films in inventory with more than 3 copies at store_id 2
SELECT *
FROM film
WHERE film_id IN (
    SELECT film_id 
    FROM inventory
    WHERE store_id = 2
    GROUP BY film_id
    HAVING COUNT(*) > 3
);

-- 20. Get customer names who made a payment on 2020-01-25
SELECT 
    first_name, 
    last_name
FROM customer
WHERE customer_id IN (
    SELECT customer_id
    FROM payment
    WHERE DATE(payment_date) = '2020-01-25'
);

-- 21. Get customers who spent more than $100 and are based in California
SELECT 
    first_name, 
    email
FROM customer
WHERE customer_id IN (
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    HAVING SUM(amount) > 100
) AND customer_id IN (
    SELECT customer_id
    FROM customer
    INNER JOIN address ON address.address_id = customer.address_id
    WHERE district = 'California'
);

-- 22. Calculate average lifetime spending per customer
SELECT 
    ROUND(AVG(total_amount), 2) AS avg_lifetime_spent
FROM (
    SELECT customer_id, SUM(amount) AS total_amount 
    FROM payment
    GROUP BY customer_id
) AS total_spent;

-- 23. Calculate average daily revenue
SELECT 
    ROUND(AVG(amount_per_day), 2) AS daily_rev_avg
FROM (
    SELECT 
        SUM(amount) AS amount_per_day,
        DATE(payment_date)
    FROM payment
    GROUP BY DATE(payment_date)
) AS daily_totals;

-- 24. Include the average payment amount alongside payment records
SELECT 
    *, 
    (SELECT ROUND(AVG(amount), 2) FROM payment) AS avg_payment_amount
FROM payment;

-- 25. Calculate the difference from the maximum payment amount for each record
SELECT 
    *, 
    (SELECT MAX(amount) FROM payment) - amount AS difference 
FROM payment;

-- 26. Get records of payments that are the maximum for each customer
SELECT * 
FROM payment p1
WHERE amount = (
    SELECT MAX(amount) 
    FROM payment p2
    WHERE p1.customer_id = p2.customer_id
)
ORDER BY customer_id;

-- 27. Find the film with the minimum replacement cost for each rating
SELECT title, film_id, replacement_cost, rating
FROM film f1
WHERE replacement_cost = (
    SELECT MIN(replacement_cost) 
    FROM film f2
    WHERE f1.rating = f2.rating
);

-- List of all customers with their total payments
SELECT cu.customer_id, 
       CONCAT(first_name, ' ', last_name) AS full_name,
       SUM(p.amount) AS total_payments
FROM customer cu
LEFT JOIN payment p ON cu.customer_id = p.customer_id
GROUP BY cu.customer_id, first_name, last_name
ORDER BY total_payments DESC;

-- Find customers with no payments
SELECT cu.customer_id, 
       CONCAT(first_name, ' ', last_name) AS full_name
FROM customer cu
LEFT JOIN payment p ON cu.customer_id = p.customer_id
WHERE p.customer_id IS NULL;

-- Total number of films in each rating category
SELECT rating, 
       COUNT(film_id) AS total_films
FROM film
GROUP BY rating
ORDER BY total_films DESC;

-- Average rental duration of films
SELECT AVG(rental_duration) AS avg_rental_duration
FROM film;

-- List of films with their inventory count
SELECT f.title, 
       COUNT(i.inventory_id) AS inventory_count
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
GROUP BY f.film_id, f.title;

-- Most popular film by rental count
SELECT f.title, 
       COUNT(r.rental_id) AS rental_count
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.title
ORDER BY rental_count DESC
LIMIT 1;

-- Find films with a replacement cost greater than the average
SELECT title, replacement_cost
FROM film
WHERE replacement_cost > (SELECT AVG(replacement_cost) FROM film);

-- List of all customers with their addresses
SELECT CONCAT(first_name, ' ', last_name) AS full_name, 
       ad.address, 
       ad.district
FROM customer cu
JOIN address ad ON cu.address_id = ad.address_id
ORDER BY full_name;

-- Total payments made by customers from each district
SELECT ad.district, 
       SUM(p.amount) AS total_payments
FROM payment p
JOIN customer cu ON p.customer_id = cu.customer_id
JOIN address ad ON cu.address_id = ad.address_id
GROUP BY ad.district
ORDER BY total_payments DESC;

-- Find films rented by a specific customer (e.g., customer_id = 1)
SELECT f.title, 
       r.rental_date
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
WHERE p.customer_id = 1
ORDER BY r.rental_date DESC;

-- Count the number of films rented on a specific date
SELECT COUNT(*) AS films_rented_count
FROM rental
WHERE rental_date = '2020-01-01';

-- List of staff who processed payments over a certain amount (e.g., > $50)
SELECT staff_id, 
       COUNT(p.payment_id) AS high_value_payments
FROM payment p
WHERE p.amount > 50
GROUP BY staff_id
ORDER BY high_value_payments DESC;

-- Retrieve films with a description longer than a specific length (e.g., 200 characters)
SELECT title, 
       LENGTH(description) AS description_length
FROM film
WHERE LENGTH(description) > 200;

-- Find the average time between rentals for each customer
SELECT customer_id, 
       AVG(DATEDIFF(r2.rental_date, r1.rental_date)) AS avg_days_between_rentals
FROM rental r1
JOIN rental r2 ON r1.customer_id = r2.customer_id AND r1.rental_id <> r2.rental_id
GROUP BY customer_id;

-- Identify the top 5 customers by total rental amount
SELECT cu.customer_id, 
       CONCAT(first_name, ' ', last_name) AS full_name, 
       SUM(p.amount) AS total_rental_amount
FROM customer cu
JOIN payment p ON cu.customer_id = p.customer_id
GROUP BY cu.customer_id, first_name, last_name
ORDER BY total_rental_amount DESC
LIMIT 5;

-- Count the number of distinct films rented in a given time frame
SELECT COUNT(DISTINCT r.inventory_id) AS distinct_films_rented
FROM rental r
WHERE r.rental_date BETWEEN '2020-01-01' AND '2020-01-31';

-- Retrieve customers who made their first payment on a specific date
SELECT cu.customer_id, 
       CONCAT(first_name, ' ', last_name) AS full_name
FROM customer cu
JOIN payment p ON cu.customer_id = p.customer_id
WHERE p.payment_date = (SELECT MIN(payment_date) 
                         FROM payment 
                         WHERE customer_id = cu.customer_id);

