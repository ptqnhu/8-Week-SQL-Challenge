-- A. Pizza Metrics
-- 1. How many pizzas were ordered?

SELECT COUNT(order_id) AS pizza_order_count
FROM ##customer_orders;


-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS unique_order_count
FROM ##customer_orders;


-- 3. How many successful orders were delivered by each runner?

SELECT
    runner_id
    , COUNT(order_id) AS successful_orders
FROM ##runner_orders
WHERE cancellation is NULL
GROUP BY runner_id;


-- 4. How many of each type of pizza was delivered?

SELECT
    pn.pizza_name
    , COUNT(co.order_id) AS delivered_pizza_count
FROM ##customer_orders AS co
    LEFT JOIN ##runner_orders AS ro ON co.order_id = ro.order_id
    LEFT JOIN pizza_runner.pizza_names AS pn ON co.pizza_id = pn.pizza_id
WHERE cancellation IS NULL
GROUP BY pn.pizza_name;


-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT
    co.customer_id
    , pn.pizza_name
    , COUNT(co.pizza_id) AS pizza_count
FROM ##customer_orders AS co
    LEFT JOIN pizza_runner.pizza_names AS pn ON co.pizza_id = pn.pizza_id
GROUP BY
    co.customer_id
    , pn.pizza_name
ORDER BY co.customer_id ASC;


-- 6. What was the maximum number of pizzas delivered in a single order?

WITH pizza_count_per_order AS (
    SELECT
        co.order_id
        , COUNT(co.pizza_id) AS pizza_count
    FROM ##customer_orders AS co
        INNER JOIN ##runner_orders AS ro ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL
    GROUP BY co.order_id
)
SELECT MAX(pizza_count) AS peak_pizza_count_per_order
FROM pizza_count_per_order;


-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT
    co.customer_id
    , SUM(
        CASE
            WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS at_least_1_change
    , SUM(
        CASE
            WHEN exclusions IS NULL AND extras IS NULL THEN 1
            ELSE 0
        END
    ) AS no_changes
FROM ##customer_orders AS co 
    INNER JOIN ##runner_orders AS ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id;


-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT
    COUNT(co.pizza_id) AS count_w_exclusions_extras
FROM ##customer_orders AS co
    INNER JOIN ##runner_orders AS ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL AND exclusions IS NOT NULL AND extras IS NOT NULL;


-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT
    DATEPART(HOUR, order_time) AS hour_of_the_day
    , COUNT(order_id) AS pizza_count
FROM ##customer_orders
GROUP BY DATEPART(HOUR, order_time);


-- 10. What was the volume of orders for each day of the week?

SELECT
    DATENAME(WEEKDAY, order_time) AS day_of_the_week
    , COUNT(order_id) AS number_of_orders
FROM ##customer_orders
GROUP BY
    DATENAME(WEEKDAY, order_time)
    , DATEPART(WEEKDAY, order_time)
ORDER BY DATEPART(WEEKDAY, order_time) ASC;
