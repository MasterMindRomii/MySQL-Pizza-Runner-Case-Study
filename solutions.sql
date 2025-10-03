-- A. Pizza Metrics (Basic Level)

-- 1. How many pizzas were ordered?

SELECT COUNT(*) as num_pizzas_ordered
FROM customer_orders;


-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT customer_id) as num_unique_orders
FROM customer_orders;


-- 3. How many successful orders were delivered by each runner?

SELECT runner_id, COUNT(*) as num_successful_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?

SELECT pizza_names.pizza_name, COUNT(*) as num_delivered
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.cancellation IS NULL
GROUP BY pizza_names.pizza_name;

--5. How many vegetarians and Meatlovers were ordered by each customer?

SELECT customer_id, 
       SUM(CASE WHEN pizza_names.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS num_meatlovers,
       SUM(CASE WHEN pizza_names.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS num_vegetarian
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY customer_id;

--6. What was the maximum number of pizzas delivered in a single order?

SELECT MAX(num_pizzas) AS max_pizzas_per_order
FROM (
  SELECT order_id, COUNT(*) AS num_pizzas
  FROM customer_orders
  JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
  WHERE runner_orders.cancellation IS NULL 
  GROUP BY order_id
) AS pizza_counts;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT customer_id, 
       SUM(CASE WHEN exclusions <> '' OR extras <> '' THEN 1 ELSE 0 END) AS num_pizzas_with_changes,
       SUM(CASE WHEN exclusions = '' AND extras = '' THEN 1 ELSE 0 END) AS num_pizzas_with_no_changes
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.cancellation IS NULL
GROUP BY customer_id;


-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT COUNT(*) AS num_pizzas_with_both_exclusions_and_extras
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.cancellation IS NULL
AND exclusions <> ''
AND extras <> '';

-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT HOUR(order_time) AS hour_of_day, COUNT(*) AS num_pizzas_ordered
FROM customer_orders
GROUP BY hour_of_day;

-- 10. What was the volume of orders for each day of the week?

SELECT DAYNAME(order_time) AS day_of_week, COUNT(*) AS num_orders
FROM customer_orders
GROUP BY day_of_week;


-- B. Runner and Customer Experience

-- Q1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
    YEARWEEK(registration_date, 1) AS week, 
    COUNT(*) AS num_runners
FROM 
    runners
Where registration_date >= 01-01-2021
GROUP BY 
    YEARWEEK(registration_date, 1);

# This query uses the YEARWEEK() function to group the runner registrations by week, starting from January 1st. The result will show the number of runners signed up for each week.

-- Q2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT 
    runner_id, 
    AVG(TIME_TO_SEC(TIMEDIFF(pickup_time, order_time))/60) AS avg_pickup_time_in_minutes
FROM 
    runner_orders
JOIN 
    customer_orders ON runner_orders.order_id = customer_orders.order_id
GROUP BY 
    runner_id;
# This query joins the runner_orders and customer_orders tables on the order_id column and calculates the average pickup time in minutes for each runner.

-- Q3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT 
    COUNT(*) AS num_pizzas,
    AVG(TIME_TO_SEC(TIMEDIFF(pickup_time, order_time))/60) AS avg_prep_time_in_minutes
FROM 
    customer_orders
JOIN 
    runner_orders ON customer_orders.order_id = runner_orders.order_id
GROUP BY 
    num_pizzas;

# This query joins the customer_orders and runner_orders tables on the order_id column and groups the results by the number of pizzas in the order. The query calculates the average preparation time in minutes for each number of pizzas.

-- Q4. What was the average distance travelled for each customer?

SELECT 
    customer_id,
    AVG(distance) AS avg_distance
FROM 
    runner_orders
JOIN 
    customer_orders ON runner_orders.order_id = customer_orders.order_id
GROUP BY 
    customer_id;

#This query joins the runner_orders and customer_orders tables on the order_id column and groups the results by the customer_id. The query calculates the average distance travelled for each customer.

-- Q5. What was the difference between the longest and shortest delivery times for all orders?

SELECT 
    TIMEDIFF(MAX(pickup_time), MIN(order_time)) AS delivery_time_difference
FROM 
    runner_orders
JOIN 
    customer_orders ON runner_orders.order_id = customer_orders.order_id;

# This query joins the runner_orders and customer_orders tables on the order_id column and calculates the difference between the longest and shortest delivery times for all orders.

-- Q6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT 
    runner_id,
    order_id,
    distance,
    duration,
    ROUND((distance/((TIME_TO_SEC(duration))/3600)),2) AS speed
FROM 
    runner_orders
ORDER BY 
    runner_id, order_id;
# This query calculates the speed for each runner for each delivery by dividing the distance travelled by the duration of the delivery in hours. The query rounds the speed to two decimal places and orders the results by the runner_id and order_id.

-- Q7. What is the successful delivery percentage for each runner?

SELECT 
    runner_id, 
    CONCAT(ROUND((COUNT(cancellation IS NULL OR NULL) / COUNT(*) * 100), 2), '%')

-- C. Ingredient Optimisation

-- 1. To get the standard ingredients for each pizza, we can join the pizza_names table with the pizza_recipes table on the pizza_id column, and then join the pizza_recipes table with the pizza_toppings table on the toppings column. The query would be:

SELECT pizza_names.pizza_name, GROUP_CONCAT(pizza_toppings.topping_name ORDER BY pizza_toppings.topping_name SEPARATOR ', ') AS standard_toppings
FROM pizza_names
JOIN pizza_recipes ON pizza_names.pizza_id = pizza_recipes.pizza_id
JOIN pizza_toppings ON FIND_IN_SET(pizza_toppings.topping_id, pizza_recipes.toppings)
GROUP BY pizza_names.pizza_name;


-- 2. To get the most commonly added extra, we can count the number of times each extra appears in the customer_orders table, group by the extras column, and order by the count in descending order. The query would be:

SELECT extras, COUNT(*) AS extra_count
FROM customer_orders
WHERE extras != ''
GROUP BY extras
ORDER BY extra_count DESC
LIMIT 1;

-- 3. To get the most common exclusion, we can follow a similar approach as in the previous query, but grouping by the exclusions column instead. The query would be:

SELECT exclusions, COUNT(*) AS exclusion_count
FROM customer_orders
WHERE exclusions != ''
GROUP BY exclusions
ORDER BY exclusion_count DESC
LIMIT 1;

-- 4. To generate an order item for each record in the customer_orders table in the format specified, we can join the customer_orders table with the pizza_names table on the pizza_id column, and then use the extras and exclusions columns to construct the order item. The query would be:

SELECT CONCAT(pizza_names.pizza_name, IF(exclusions != '', CONCAT(' - Exclude ', exclusions), ''), IF(extras != '', CONCAT(' - Extra ', extras), '')) AS order_item
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id;

-- 5. To generate an alphabetically ordered comma separated ingredient list for each pizza order, we can join the customer_orders table with the pizza_recipes table on the pizza_id column, and then join the pizza_recipes table with the pizza_toppings table on the toppings column. We can then use the GROUP_CONCAT function to concatenate the topping_name values and add the "2x" prefix to any relevant ingredients using the CASE statement. The query would be:

SELECT
  pn.pizza_name,
  GROUP_CONCAT(
    CONCAT(
      CASE WHEN FIND_IN_SET(pt.topping_name, co.exclusions) > 0 THEN '' ELSE '2x' END,
      pt.topping_name
    ) ORDER BY pt.topping_name ASC SEPARATOR ', '
  ) AS ingredients_list
FROM
  customer_orders co
  JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
  JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
  JOIN pizza_toppings pt ON FIND_IN_SET(pt.topping_id, pr.toppings)
GROUP BY
  co.order_id;

-- 6. To find the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first, we can use the following MySQL query:
SELECT
  pt.topping_name,
  SUM(
    IF(FIND_IN_SET(pt.topping_id, pr.toppings) AND FIND_IN_SET(co.order_id, ro.order_id), 1, 0)
  ) AS total_quantity
FROM
  customer_orders co
  JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
  JOIN pizza_toppings pt ON FIND_IN_SET(pt.topping_id, pr.toppings)
  LEFT JOIN runner_orders ro ON co.order_id = ro.order_id AND ro.cancellation IS NULL
GROUP BY
  pt.topping_id
ORDER BY
  total_quantity DESC;

# Note: The above queries assume that all delivered pizzas have a corresponding entry in the runner_orders table with a null value in the cancellation column. If this assumption does not hold, we need to modify the queries accordingly.

-- D. Pricing and Ratings

-- 1. To calculate the total revenue of Pizza Runner, we can join the customer_orders table with the pizza_names table and use the price information to calculate the total revenue.

-- Without extras:

SELECT SUM(
  CASE
    WHEN pizza_name = 'Meatlovers' THEN 12
    WHEN pizza_name = 'Vegetarian' THEN 10
    ELSE 0
  END
) AS total_revenue
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id;

-- 2. With extras and extra cheese costing $1:


SELECT SUM(
  CASE
    WHEN pizza_name = 'Meatlovers' THEN 12 + 1*LENGTH(extras)
    WHEN pizza_name = 'Vegetarian' THEN 10 + 1*LENGTH(extras)
    ELSE 0
  END
) AS total_revenue
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id;


-- 3. To add a ratings system, we can create a new table called "delivery_ratings" with the following schema:

CREATE TABLE delivery_ratings (
  "rating_id" INTEGER PRIMARY KEY,
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "customer_rating" INTEGER
);

-- 4. We can then insert data for each successful customer order between 1 to 5:

INSERT INTO delivery_ratings ("rating_id", "order_id", "runner_id", "customer_rating")
VALUES
  (1, 1, 1, 4),
  (2, 2, 1, 3),
  (3, 3, 1, 5);

-- 5. To join all of the information together for successful deliveries, we can use the following query:

SELECT
  customer_orders.customer_id,
  customer_orders.order_id,
  runner_orders.runner_id,
  delivery_ratings.customer_rating AS rating,
  customer_orders.order_time,
  runner_orders.pickup_time,
  TIME(runner_orders.pickup_time - customer_orders.order_time) AS time_between_order_and_pickup,
  TIME(runner_orders.delivery_time - runner_orders.pickup_time) AS delivery_duration,
  ROUND(REPLACE(runner_orders.distance, 'km', '') / REPLACE(runner_orders.duration, 'minutes', '') * 60, 2) AS average_speed,
  COUNT(customer_orders.pizza_id) AS total_number_of_pizzas
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
JOIN delivery_ratings ON customer_orders.order_id = delivery_ratings.order_id
WHERE runner_orders.cancellation IS NULL
GROUP BY customer_orders.order_id;
This will give us a table with the requested information for successful deliveries.

--6. To calculate the amount of money Pizza Runner has left over after the deliveries, we can use the following query:


SELECT
  SUM(
    CASE
      WHEN pizza_name = 'Meatlovers' THEN 12 + 1*LENGTH(extras)
      WHEN pizza_name = 'Vegetarian' THEN 10 + 1*LENGTH(extras)
      ELSE 0
    END
  ) - (0.3 * REPLACE(runner_orders.distance, 'km', '')) AS net_profit
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.cancellation IS NULL;

# This will give us the amount of money Pizza Runner has left over after paying the runners. Note that we assume that there are no other costs involved in the deliveries.
